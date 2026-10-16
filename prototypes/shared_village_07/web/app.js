'use strict';
const $ = id => document.getElementById(id);
let setup = false;
const confirmations = new Set(['restore','skill','teleport','revoke','release_settings']);
async function api(path, body) {
  const response = await fetch('/api/' + path, body === undefined ? {} : {method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
  const result = await response.json();
  if (!response.ok) throw new Error(result.message || 'Request failed');
  return result;
}
function showError(error) { $('message').textContent = error.message; }
function options(select, values) {
  const previous = select.value;
  select.replaceChildren(...values.map(([value,label]) => new Option(label,value)));
  if (values.some(([value]) => value === previous)) select.value = previous;
}
async function refresh() {
  const session = await api('session'); setup = session.setup;
  $('login').hidden = session.authenticated;
  $('console').hidden = !session.authenticated;
  $('logout').hidden = !session.authenticated;
  $('bootstrap-label').hidden = !setup;
  $('login-title').textContent = setup ? 'Create the administrator' : 'Sign in';
  if (!session.authenticated) { $('message').textContent = session.error || (setup ? 'Initial setup required.' : 'Sign in to administer this world.'); return; }
  const state = await api('status');
  $('world-status').textContent = state.frozen ? 'RECOVERY REQUIRED: ' + state.error : state.paused ? 'World paused' : 'World running';
  $('build').textContent = 'Build ' + state.build.slice(0,12) + ' · ' + state.protocol + ' · ' + state.players.filter(p => p.online).length + ' connected';
  $('storage').textContent = state.admin_error || 'Administration and audit records are separate from world backups.';
  for (const [key,value] of Object.entries({...state.config,...state.release})) {
    const input = document.querySelector('[name="' + key + '"]');
    if (input && document.activeElement !== input) input.value = value;
  }
  options($('backups'),state.recovery_points.map(name => [name,name]));
  if (state.frozen && state.recovery_source) $('backups').value = state.recovery_source;
  options($('player'),state.players.map(p => [p.id,p.name + (p.online ? ' (online)' : ' (offline)') + (p.role ? ' · ' + p.role : '')]));
  const formatter = new Intl.DateTimeFormat('en-US',{timeZone:'America/Chicago',dateStyle:'medium',timeStyle:'medium'});
  $('audit').replaceChildren(...state.audit.slice().reverse().map(row => {
    const tr = document.createElement('tr');
    for (const value of [formatter.format(new Date(row.utc + 'Z')),row.actor,row.action,row.outcome]) {
      const td = document.createElement('td'); td.textContent = value; tr.append(td);
    }
    return tr;
  }));
}
async function action(name, args = {}) {
  if (confirmations.has(name) && !window.confirm('Confirm ' + name.replaceAll('_',' ') + '?')) return;
  args.confirmed = confirmations.has(name); args.player = $('player').value;
  const result = await api('action',{action:name,arguments:args});
  $('result').textContent = result.code ? result.message + '\n' + result.code : result.player ? JSON.stringify(result.player,null,2) : '';
  await refresh(); $('message').textContent = result.message;
}
$('credentials').addEventListener('submit',async event => {
  event.preventDefault(); const button = event.target.querySelector('button'); button.disabled = true;
  try { await api(setup ? 'setup' : 'login',Object.fromEntries(new FormData(event.target))); event.target.reset(); await refresh(); $('message').textContent = 'Signed in.'; }
  catch(error) { showError(error); } finally { button.disabled = false; }
});
for (const form of document.querySelectorAll('form[data-action]')) form.addEventListener('submit',async event => {
  event.preventDefault(); const args = {};
  for (const input of form.querySelectorAll('[name]')) args[input.name] = input.type === 'number' ? Number(input.value) : input.value;
  const button = form.querySelector('button'); button.disabled = true;
  try { await action(form.dataset.action,args); } catch(error) { showError(error); } finally { button.disabled = false; }
});
for (const button of document.querySelectorAll('button[data-action]')) button.addEventListener('click',async () => {
  const args = {}; if (button.dataset.paused) args.paused = button.dataset.paused === 'true'; if (button.dataset.role) args.role = button.dataset.role;
  button.disabled = true;
  try { await action(button.dataset.action,args); } catch(error) { showError(error); } finally { button.disabled = false; }
});
$('refresh').onclick = () => refresh().catch(showError);
$('logout').onclick = async () => { try { await api('logout',{}); $('result').textContent = ''; await refresh(); } catch(error) { showError(error); } };
refresh().catch(showError);

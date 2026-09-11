# Comfort 02 review notes

Separate review pass after implementation, before packaging. Local prototype only; no PR or release implied.

- Road layout is checked against all planted field rectangles. Fences render from the same barrier rectangles used by the headless travel grid. Both travel modes retain hard obstacle and water restrictions.
- Route preference uses per-cell travel costs, independent of walk/run pace. The heuristic uses the minimum cost so road preference does not overestimate the remaining route cost. No jump optimization bypasses weights.
- Hover preview cannot issue a movement command. Click computes a fresh route from the actual traveler position. This is a static map; dynamic obstacles and other actors are later work.
- Inspection moves in small steps and checks the navigation footprint before each step, maintaining ground/bridge height plus eye height. Returning to overhead restores its prior zoom/elevation; Space restores traveler following.
- Held rotation uses elapsed time and releases without accumulating additional turns. Zoom slider resolution was corrected after a check exposed rounding of small held-key steps.
- Key rebinding rejects conflicts and reserves Shift for running and Escape for cancellation. Controls and route preference have GUI access and working defaults. Save/reload checks use a separate test file, preserving real preferences.
- Art limitations remain: flat terrain, simplified distant ground, existing people/foliage and building close-up quality. Bridges are deliberately unchanged. The app-icon art study is still a follow-up.

Verification logs and actual packaged Linux captures belong in artifacts/. Windows requires Scott's next playtest. Main-project architecture, server implementation and live infrastructure are unchanged.

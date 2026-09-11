extends RefCounted
# PBKDF2-HMAC-SHA256, one 32-byte block. Called on a dedicated thread.
const ITERATIONS = 600000
static func derive(password: String, salt_hex: String, rounds: int = ITERATIONS) -> String:
	var crypto := Crypto.new()
	var key := password.to_utf8_buffer()
	var salt := salt_hex.hex_decode()
	salt.append_array(PackedByteArray([0,0,0,1]))
	var u := crypto.hmac_digest(HashingContext.HASH_SHA256,key,salt)
	var result := u.duplicate()
	for _iteration in range(1,rounds):
		u = crypto.hmac_digest(HashingContext.HASH_SHA256,key,u)
		for i in range(32): result[i] = result[i] ^ u[i]
	return result.hex_encode()

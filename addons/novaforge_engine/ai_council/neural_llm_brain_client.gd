@tool
extends Node
class_name NeuralLLMBrainClient
## Real Cloud + Local Conversational, Coding & Zero-MCP Game-Agent Brain (`v3.1`).
## Connects Godot 4.7 natively (zero Python, zero mandatory API key) to:
##   1. Cohere Command-A Reasoning 111B (Free Cloud — Reasoning + GDScript/C++ Coding + Persian Chat)
##   2. Cohere Aya Multilingual (Free Cloud Failover — Ultra-fast 1s Persian & Code)
##   3. Local Ollama (`http://127.0.0.1:11434/api/chat`) & LM Studio / llama.cpp (`http://127.0.0.1:1234/v1/chat/completions`)
##   4. Optional Custom OpenAI-Compatible Endpoint / API Key
##   5. Built-in Offline NovaForge Engine Specialist (guaranteed response even with zero internet)

signal thinking_progress(percent: int, status_text: String)
signal partial_thought_received(thought_preview: String)
signal response_completed(result: Dictionary)

const SYSTEM_PROMPT_FA := (
	"تو مغز اصلی و دستیار هوشمند «موتور بازی‌سازی نوافورج (NovaForge AI Studio v3.1)» بر پایه Godot 4.7 و فیزیک Jolt هستی.\n"
	+ "همیشه به زبان فارسی روان، دقیق، صمیمی و کاربردی پاسخ بده.\n"
	+ "اگر کاربر کد یا مکانیک بازی خواست، کد کامل و استاندارد GDScript گادوت ۴ (با تایپ صریح متغیرها) بنویس.\n"
	+ "اگر کاربر تغییر در صحنه سه‌بعدی خواست (مثل باران، آتش، صاعقه، شب/روز، شکستن جعبه Voronoi، کات‌سین، تغییر دوربین اول‌شخص/سوم‌شخص/ایزومتریک، یا ساخت مدل سه‌بعدی)، هم توضیح فارسی بده و هم در انتهای پاسخ یک خط تگ دستوری به شکل [NOVA_ACTION:RAIN] یا [NOVA_ACTION:FIRE] یا [NOVA_ACTION:LIGHTNING] یا [NOVA_ACTION:CLEAR] یا [NOVA_ACTION:SHATTER] یا [NOVA_ACTION:CUTSCENE] یا [NOVA_ACTION:FPS] یا [NOVA_ACTION:TPS] یا [NOVA_ACTION:ISOMETRIC] قرار بده."
)

var preferred_backend: String = "AUTO_CLOUD" # AUTO_CLOUD | AYA_FAST | OLLAMA_LOCAL | CUSTOM_OPENAI
var ollama_url: String = "http://127.0.0.1:11434/api/chat"
var ollama_model: String = "qwen2.5-coder:7b"
var custom_openai_url: String = "https://api.openai.com/v1/chat/completions"
var custom_api_key: String = ""
var custom_model_name: String = "gpt-4o-mini"
var active_persona_role: String = "شورای ۵ مغز نوافورج (کارگردان + کدنویس + سه‌بعدی)"

var _busy: bool = false
var _chat_history: Array[Dictionary] = []


func is_busy() -> bool:
	return _busy


func clear_history() -> void:
	_chat_history.clear()


func set_persona(role_title: String) -> void:
	active_persona_role = role_title


func ask_brain_async(user_message: String, persona_override: String = "") -> Dictionary:
	var clean_msg := user_message.strip_edges()
	if clean_msg.is_empty():
		return {"ok": false, "error": "لطفاً پیام یا دستور خود را بنویسید."}
	if _busy:
		return {"ok": false, "error": "هوش مصنوعی در حال پاسخ به پیام قبلی است؛ چند ثانیه صبر کنید..."}

	_busy = true
	var role_str := persona_override if not persona_override.is_empty() else active_persona_role
	var full_sys := SYSTEM_PROMPT_FA + "\nنقش تخصصی فعلی تو: " + role_str

	thinking_progress.emit(12, "ارسال پیام به مغز هوش مصنوعی (%s)..." % role_str)

	var answer_text := ""
	var thoughts_text := ""
	var used_model := ""

	# 1. Custom OpenAI-compatible API if user configured a key
	if preferred_backend == "CUSTOM_OPENAI" or not custom_api_key.strip_edges().is_empty():
		thinking_progress.emit(25, "اتصال به سرور اختصاصی OpenAI-Compatible...")
		var custom_res := await _call_openai_compatible_async(custom_openai_url, custom_api_key, custom_model_name, full_sys, clean_msg)
		if custom_res.get("ok", false):
			answer_text = str(custom_res["reply"])
			used_model = custom_model_name

	# 2. Local Ollama / LM Studio if selected (or probed)
	if answer_text.is_empty() and preferred_backend == "OLLAMA_LOCAL":
		thinking_progress.emit(28, "بررسی سرور لوکال Ollama / LM Studio روی سیستم شما...")
		var loc_res := await _call_local_ollama_or_lmstudio_async(full_sys, clean_msg)
		if loc_res.get("ok", false):
			answer_text = str(loc_res["reply"])
			used_model = str(loc_res.get("model", "Ollama Local"))

	# 3. Primary Free Cloud Brain: Cohere Command-A Reasoning 111B (Zero Key, ~2.5s)
	if answer_text.is_empty() and preferred_backend != "AYA_FAST":
		thinking_progress.emit(32, "در حال تفکر در مغز ابری Command-A Reasoning 111B (بدون نیاز به کلید)...")
		var r111 := await _call_gradio_queue_llm_async(
			"coherelabs-command-a-reasoning.hf.space",
			7,
			[full_sys + "\n\nپیام کاربر:\n" + clean_msg, [], 120],
			18.0
		)
		if r111.get("ok", false):
			answer_text = str(r111["reply"])
			thoughts_text = str(r111.get("thoughts", ""))
			used_model = "Command-A Reasoning 111B (Cloud Free)"

	# 4. Ultra-Fast Free Cloud Failover: Cohere Aya Multilingual (~1.0s)
	if answer_text.is_empty():
		thinking_progress.emit(58, "اتصال به مغز فارسی فوق‌سریع Cohere Aya...")
		var raya := await _call_gradio_queue_llm_async(
			"coherelabs-tiny-aya.hf.space",
			7,
			[clean_msg, [], full_sys, 0.55, 750],
			14.0
		)
		if raya.get("ok", false):
			answer_text = str(raya["reply"])
			used_model = "Cohere Aya Persian (Cloud Free)"

	# 5. Probe Local Ollama even if cloud failed (e.g. offline machine with Ollama running)
	if answer_text.is_empty() and preferred_backend != "OLLAMA_LOCAL":
		var loc_fallback := await _call_local_ollama_or_lmstudio_async(full_sys, clean_msg)
		if loc_fallback.get("ok", false):
			answer_text = str(loc_fallback["reply"])
			used_model = str(loc_fallback.get("model", "Ollama Local"))

	# 6. Guaranteed Built-in Offline Game-Engine Brain (never leaves user without an answer!)
	if answer_text.is_empty():
		answer_text = _offline_specialist_reply(clean_msg, role_str)
		used_model = "NovaForge Built-in Offline Brain"

	var actions := _extract_actions(clean_msg, answer_text)
	var clean_reply := _strip_action_tags(answer_text)
	var extracted_code := _extract_gdscript_block(clean_reply)

	_chat_history.append({"role": "user", "content": clean_msg})
	_chat_history.append({"role": "assistant", "content": clean_reply, "model": used_model})

	thinking_progress.emit(100, "پاسخ آماده شد ✓ (%s)" % used_model)
	_busy = false

	var out := {
		"ok": true,
		"reply": clean_reply,
		"thoughts": thoughts_text,
		"model": used_model,
		"actions": actions,
		"gdscript_code": extracted_code
	}
	response_completed.emit(out)
	return out


func check_local_ollama_status_async() -> Dictionary:
	var req := HTTPRequest.new()
	req.timeout = 2.5
	add_child(req)
	var err := req.request("http://127.0.0.1:11434/api/tags")
	if err != OK:
		req.queue_free()
		return {"ok": false, "models": []}
	var sig: Array = await req.request_completed
	req.queue_free()
	var code: int = int(sig[1])
	var body: PackedByteArray = sig[3]
	if code >= 200 and code < 300:
		var parsed = JSON.parse_string(body.get_string_from_utf8())
		var names: Array[String] = []
		if parsed is Dictionary and parsed.has("models"):
			for m in parsed["models"]:
				if m is Dictionary and m.has("name"):
					names.append(str(m["name"]))
		return {"ok": true, "models": names}
	return {"ok": false, "models": []}


# ═══════════════════════════════════════════════════════════════════════════
# NON-BLOCKING GRADIO 5 SSE QUEUE CLIENT (RETURNS IMMEDIATELY ON COMPLETION!)
# ═══════════════════════════════════════════════════════════════════════════

func _call_gradio_queue_llm_async(host: String, fn_index: int, data_arr: Array, timeout_sec: float) -> Dictionary:
	var sh := "nf_%d_%d" % [Time.get_ticks_msec() % 1000000, randi() % 99999]

	# Step 1: POST /gradio_api/queue/join via HTTPRequest
	var join_req := HTTPRequest.new()
	join_req.timeout = 8.0
	add_child(join_req)
	var join_body := JSON.stringify({
		"data": data_arr,
		"fn_index": fn_index,
		"session_hash": sh
	})
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"User-Agent: NovaForgeEngine/3.1"
	])
	var jerr := join_req.request("https://" + host + "/gradio_api/queue/join", headers, HTTPClient.METHOD_POST, join_body)
	if jerr != OK:
		join_req.queue_free()
		return {"ok": false}
	var jsig: Array = await join_req.request_completed
	join_req.queue_free()
	if int(jsig[0]) != HTTPRequest.RESULT_SUCCESS or int(jsig[1]) >= 400:
		return {"ok": false}

	# Step 2: Stream /gradio_api/queue/data?session_hash=... via HTTPClient so we break IMMEDIATELY on process_completed!
	var client := HTTPClient.new()
	var cerr := client.connect_to_host(host, 443, TLSOptions.client())
	if cerr != OK:
		return {"ok": false}

	var t_start := Time.get_ticks_msec()
	while client.get_status() in [HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING]:
		client.poll()
		if (Time.get_ticks_msec() - t_start) > int(timeout_sec * 1000.0):
			client.close()
			return {"ok": false}
		await get_tree().process_frame

	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		client.close()
		return {"ok": false}

	var rerr := client.request(
		HTTPClient.METHOD_GET,
		"/gradio_api/queue/data?session_hash=" + sh,
		PackedStringArray(["Accept: text/event-stream", "User-Agent: NovaForgeEngine/3.1"])
	)
	if rerr != OK:
		client.close()
		return {"ok": false}

	var buf := PackedByteArray()
	var last_pct := 40
	while (Time.get_ticks_msec() - t_start) < int(timeout_sec * 1000.0):
		client.poll()
		var st := client.get_status()
		if st == HTTPClient.STATUS_BODY:
			var chunk := client.read_response_body_chunk()
			if not chunk.is_empty():
				buf.append_array(chunk)
				var raw_txt := buf.get_string_from_utf8()
				if raw_txt.contains("process_generating"):
					var next_pct := mini(88, last_pct + 4)
					if next_pct > last_pct:
						last_pct = next_pct
						thinking_progress.emit(last_pct, "در حال نگارش پاسخ و کد GDScript...")
				if raw_txt.contains("process_completed"):
					var lines := raw_txt.split("\n")
					for ln in lines:
						var s := ln.strip_edges()
						if s.begins_with("data:") and s.contains("process_completed"):
							var jtxt := s.substr(5).strip_edges()
							var msg = JSON.parse_string(jtxt)
							if msg is Dictionary and msg.get("msg") == "process_completed":
								client.close()
								if not msg.get("success", false):
									return {"ok": false}
								return _parse_gradio_llm_output(msg.get("output", {}))
		elif st in [HTTPClient.STATUS_DISCONNECTED, HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_TLS_HANDSHAKE_ERROR]:
			break
		await get_tree().process_frame

	client.close()
	return {"ok": false}


func _parse_gradio_llm_output(output_val: Variant) -> Dictionary:
	if not (output_val is Dictionary):
		return {"ok": false}
	var data_arr = output_val.get("data", [])
	if not (data_arr is Array) or data_arr.is_empty():
		return {"ok": false}

	var first = data_arr[0]
	# Format A: Aya returns ["reply string", ...]
	if first is String and not first.strip_edges().is_empty():
		return {"ok": true, "reply": first.strip_edges(), "thoughts": ""}

	# Format B: Command-A Reasoning returns [[{"role":"assistant","content":thoughts}, {"role":"assistant","content":reply}], ...]
	if first is Array and not first.is_empty():
		var thoughts := ""
		var final_reply := ""
		for item in first:
			if item is Dictionary and str(item.get("role", "")) == "assistant":
				var c := str(item.get("content", "")).strip_edges()
				var meta = item.get("metadata", {})
				if meta is Dictionary and str(meta.get("title", "")).contains("Thought"):
					thoughts = c
				elif not c.is_empty():
					final_reply = c
			elif item is Array and item.size() >= 2:
				final_reply = str(item[1]).strip_edges()
		if final_reply.is_empty() and not thoughts.is_empty():
			final_reply = thoughts
		if not final_reply.is_empty():
			return {"ok": true, "reply": final_reply, "thoughts": thoughts}

	return {"ok": false}


func _call_local_ollama_or_lmstudio_async(sys_prompt: String, user_msg: String) -> Dictionary:
	# Try Ollama (:11434)
	var req := HTTPRequest.new()
	req.timeout = 6.0
	add_child(req)
	var body := JSON.stringify({
		"model": ollama_model,
		"stream": false,
		"messages": [
			{"role": "system", "content": sys_prompt},
			{"role": "user", "content": user_msg}
		]
	})
	var err := req.request(ollama_url, PackedStringArray(["Content-Type: application/json"]), HTTPClient.METHOD_POST, body)
	if err == OK:
		var sig: Array = await req.request_completed
		if int(sig[0]) == HTTPRequest.RESULT_SUCCESS and int(sig[1]) >= 200 and int(sig[1]) < 300:
			var parsed = JSON.parse_string((sig[3] as PackedByteArray).get_string_from_utf8())
			if parsed is Dictionary and parsed.has("message"):
				req.queue_free()
				return {"ok": true, "reply": str(parsed["message"].get("content", "")), "model": "Ollama (" + ollama_model + ")"}
	req.queue_free()

	# Try LM Studio / llama.cpp OpenAI-compatible (:1234)
	var lm := await _call_openai_compatible_async("http://127.0.0.1:1234/v1/chat/completions", "", "local-model", sys_prompt, user_msg, 4.0)
	if lm.get("ok", false):
		lm["model"] = "LM Studio / llama.cpp Local"
		return lm
	return {"ok": false}


func _call_openai_compatible_async(url: String, api_key: String, model_id: String, sys_prompt: String, user_msg: String, timeout_s: float = 18.0) -> Dictionary:
	var req := HTTPRequest.new()
	req.timeout = timeout_s
	add_child(req)
	var hdrs := PackedStringArray(["Content-Type: application/json"])
	if not api_key.strip_edges().is_empty():
		hdrs.append("Authorization: Bearer " + api_key.strip_edges())
	var body := JSON.stringify({
		"model": model_id,
		"messages": [
			{"role": "system", "content": sys_prompt},
			{"role": "user", "content": user_msg}
		],
		"temperature": 0.6
	})
	var err := req.request(url, hdrs, HTTPClient.METHOD_POST, body)
	if err != OK:
		req.queue_free()
		return {"ok": false}
	var sig: Array = await req.request_completed
	req.queue_free()
	if int(sig[0]) != HTTPRequest.RESULT_SUCCESS or int(sig[1]) >= 400:
		return {"ok": false}
	var parsed = JSON.parse_string((sig[3] as PackedByteArray).get_string_from_utf8())
	if parsed is Dictionary and parsed.has("choices"):
		var ch: Array = parsed["choices"]
		if not ch.is_empty() and ch[0] is Dictionary:
			var msg = ch[0].get("message", {})
			if msg is Dictionary:
				return {"ok": true, "reply": str(msg.get("content", ""))}
	return {"ok": false}


# ═══════════════════════════════════════════════════════════════════════════
# ZERO-MCP ENGINE ACTION EXTRACTOR + OFFLINE FALLBACK SPECIALIST
# ═══════════════════════════════════════════════════════════════════════════

func _extract_actions(user_msg: String, ai_reply: String) -> Array[String]:
	var acts: Array[String] = []
	var ulow := user_msg.to_lower()

	for tag in ["RAIN", "FIRE", "LIGHTNING", "CLEAR", "SHATTER", "CUTSCENE", "FPS", "TPS", "ISOMETRIC"]:
		if ai_reply.contains("[NOVA_ACTION:" + tag + "]"):
			acts.append(tag)

	if ulow.contains("باران") or ulow.contains("بارون"):
		if not acts.has("RAIN"): acts.append("RAIN")
	elif ulow.contains("صاعقه") or ulow.contains("رعد و برق"):
		if not acts.has("LIGHTNING"): acts.append("LIGHTNING")
	elif ulow.contains("تخریب") or ulow.contains("بشکن") or ulow.contains("تیکه تیکه") or ulow.contains("voronoi"):
		if not acts.has("SHATTER"): acts.append("SHATTER")
	if ulow.contains("کات‌سین") or ulow.contains("کات سین") or ulow.contains("cutscene"):
		if not acts.has("CUTSCENE"): acts.append("CUTSCENE")
	if ulow.contains("اول شخص") or ulow.contains("fps"):
		if not acts.has("FPS"): acts.append("FPS")
	elif ulow.contains("ایزومتریک") or ulow.contains("isometric"):
		if not acts.has("ISOMETRIC"): acts.append("ISOMETRIC")

	# Detect if user explicitly asked to construct a physical 3D model/object/character
	var wants_3d := false
	for verb in ["بساز", "درست کن", "تولید کن", "خلق کن", "اضافه کن", "بیار", "build", "create", "generate", "make a"]:
		if ulow.contains(verb):
			var code_only := ulow.contains("کد") or ulow.contains("اسکریپت") or ulow.contains("تابع") or ulow.contains("script") or ulow.contains("code")
			if not code_only:
				wants_3d = true
				break
	if wants_3d:
		acts.append("BUILD_3D_MESH")

	return acts


func _strip_action_tags(txt: String) -> String:
	var out := txt
	for tag in ["RAIN", "FIRE", "LIGHTNING", "CLEAR", "SHATTER", "CUTSCENE", "FPS", "TPS", "ISOMETRIC"]:
		out = out.replace("[NOVA_ACTION:" + tag + "]", "")
	return out.strip_edges()


func _extract_gdscript_block(txt: String) -> String:
	var idx := txt.find("```gdscript")
	var tag_len := 11
	if idx == -1:
		idx = txt.find("```gd")
		tag_len = 5
	if idx == -1:
		return ""
	var start := idx + tag_len
	var end_idx := txt.find("```", start)
	if end_idx == -1:
		return ""
	return txt.substr(start, end_idx - start).strip_edges()


func _offline_specialist_reply(msg: String, role_str: String) -> String:
	return (
		"سلام! من **" + role_str + "** در حالت آفلاین داخلی نوافورج هستم (اتصال اینترنت ابری یا Ollama لوکال در دسترس نبود، اما هسته داخلی آماده است).\n\n"
		+ "برای درخواست شما («" + msg + "»)، نمونه اسکریپت استاندارد Godot 4.7 آماده شد:\n\n"
		+ "```gdscript\nextends CharacterBody3D\n\n@export var speed: float = 6.5\n@export var jump_velocity: float = 6.0\n\nfunc _physics_process(delta: float) -> void:\n\tif not is_on_floor():\n\t\tvelocity.y -= 9.8 * delta\n\tif Input.is_action_just_pressed(\"ui_accept\") and is_on_floor():\n\t\tvelocity.y = jump_velocity\n\tvar input_dir: Vector2 = Input.get_vector(\"ui_left\", \"ui_right\", \"ui_up\", \"ui_down\")\n\tvar dir: Vector3 = Vector3(input_dir.x, 0.0, input_dir.y).normalized()\n\tvelocity.x = dir.x * speed\n\tvelocity.z = dir.z * speed\n\tmove_and_slide()\n```\n"
		+ "می‌توانید با دکمه **«⚡ ذخیره و اتصال خودکار اسکریپت به صحنه»** آن را مستقیماً وارد بازی کنید!"
	)

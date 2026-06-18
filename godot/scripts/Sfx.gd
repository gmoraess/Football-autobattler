extends Node
## Autoload de efeitos sonoros SINTETIZADOS por código (CC0, sem arquivos).
## Uso: Sfx.play(Sfx.kick) etc. Gera os streams uma vez no _ready.

const SR := 22050

var charge: AudioStreamWAV
var kick: AudioStreamWAV
var goal: AudioStreamWAV
var save: AudioStreamWAV
var card: AudioStreamWAV

var _pool: Array = []
var _next := 0

func _ready() -> void:
	charge = _synth_charge()
	kick = _synth_kick()
	goal = _synth_goal()
	save = _synth_save()
	card = _synth_card()
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)

func play(stream: AudioStream, volume_db: float = -4.0) -> void:
	if stream == null: return
	var p: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = stream
	p.volume_db = volume_db
	p.play()

# --------------------------------------------------------------------------
func _make_wav(buf: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		var v := int(clampf(buf[i], -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SR
	w.stereo = false
	w.data = data
	return w

## Carregar finalização: tom subindo (sweep) com volume crescente.
func _synth_charge() -> AudioStreamWAV:
	var dur := 0.55
	var n := int(SR * dur)
	var buf := PackedFloat32Array(); buf.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / SR
		var prog := t / dur
		var freq := 200.0 + 650.0 * prog
		phase += TAU * freq / SR
		buf[i] = sin(phase) * (prog * prog) * 0.5
	return _make_wav(buf)

## Chute: thump grave com transiente de ruído.
func _synth_kick() -> AudioStreamWAV:
	var dur := 0.24
	var n := int(SR * dur)
	var buf := PackedFloat32Array(); buf.resize(n)
	for i in n:
		var t := float(i) / SR
		var env: float = exp(-t * 20.0)
		var freq := 120.0 * exp(-t * 9.0) + 55.0
		var s := sin(TAU * freq * t) * env
		if t < 0.025:
			s += (randf() * 2.0 - 1.0) * (1.0 - t / 0.025) * 0.5
		buf[i] = s * 0.85
	return _make_wav(buf)

## Gol: arpejo ascendente (C-E-G-C) brilhante.
func _synth_goal() -> AudioStreamWAV:
	var dur := 0.7
	var n := int(SR * dur)
	var buf := PackedFloat32Array(); buf.resize(n)
	var freqs := [523.25, 659.25, 783.99, 1046.5]
	for i in n:
		var t := float(i) / SR
		var idx: int = mini(int(t / 0.13), freqs.size() - 1)
		var f: float = freqs[idx]
		var env: float = exp(-fmod(t, 0.13) * 5.0) * (1.0 - t / dur * 0.35)
		var s := (sin(TAU * f * t) + 0.4 * sin(TAU * f * 2.0 * t)) * env
		buf[i] = s * 0.42
	return _make_wav(buf)

## Defesa: "thwack" — ruído filtrado curto com tom grave.
func _synth_save() -> AudioStreamWAV:
	var dur := 0.26
	var n := int(SR * dur)
	var buf := PackedFloat32Array(); buf.resize(n)
	for i in n:
		var t := float(i) / SR
		var env: float = exp(-t * 15.0)
		buf[i] = ((randf() * 2.0 - 1.0) * 0.5 + sin(TAU * 170.0 * t) * 0.5) * env * 0.6
	return _make_wav(buf)

## Carta jogada: tick curto/agudo.
func _synth_card() -> AudioStreamWAV:
	var dur := 0.08
	var n := int(SR * dur)
	var buf := PackedFloat32Array(); buf.resize(n)
	for i in n:
		var t := float(i) / SR
		var env: float = exp(-t * 45.0)
		buf[i] = sin(TAU * 880.0 * t) * env * 0.35
	return _make_wav(buf)

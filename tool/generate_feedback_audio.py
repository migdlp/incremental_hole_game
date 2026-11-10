"""Regenerate offline WAV bank using Python 3 + ffmpeg (build tools only)."""
import array, hashlib, json, math, pathlib, random, subprocess, wave
ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/audio/sfx'
RATE = 22050
rng = random.Random(7007)
manifest = {}
def source(kind):
    path = ROOT / f'tool/audio_sources/kenney/impact{kind}_light_000.ogg'
    raw = subprocess.check_output(['ffmpeg','-v','error','-i',str(path),'-ar',str(RATE),'-ac','1','-f','s16le','-'])
    data = array.array('h');data.frombytes(raw)
    peak = max(abs(x) for x in data) or 1
    return [x/peak for x in data]
wood, metal, glass = source('Wood'), source('Metal'), source('Glass')
def save(name, data, loop=False):
    peak=max(abs(x) for x in data) or 1
    scale=.62/peak
    if not loop:
        data=[x*min(1,i/(RATE*.003),(len(data)-1-i)/(RATE*.012)) for i,x in enumerate(data)]
    pcm=array.array('h',(round(max(-1,min(1,x*scale))*32767) for x in data))
    file=OUT/(name+'.wav')
    with wave.open(str(file),'wb') as w:
        w.setparams((1,2,RATE,0,'NONE','not compressed'));w.writeframes(pcm.tobytes())
    manifest[name]={'file':f'assets/audio/sfx/{name}.wav','duration':len(data)/RATE,'sha256':hashlib.sha256(file.read_bytes()).hexdigest()}
def synth(seconds, fn):return [fn(i/RATE,i) for i in range(round(RATE*seconds))]
def sample(data,i):return data[i] if i<len(data) else 0
for n in range(6):
    f=320+n*19
    save(f'plop{n}',synth(.14+n*.004,lambda t,i: (.6*math.sin(2*math.pi*(f*.024*(1-math.exp(-t/.024))+76*t))+ .2*math.sin(2*math.pi*61*t))*math.exp(-t/ .045)+rng.uniform(-.05,.05)*math.exp(-t/.012)))
for n,f in enumerate([1046.5,1174.66,1318.51,1567.98,1760]):
    save(f'coin{n}',synth(.19,lambda t,i:(.55*math.sin(2*math.pi*f*t)+.13*math.sin(2*math.pi*f*2.71*t))*math.exp(-t/.045)+.23*sample(metal,i)*math.exp(-t/.025)))
for n in range(2):
    save(f'coinout{n}',synth(.075,lambda t,i:.6*sample(metal,i)*math.exp(-t/.016)+.3*math.sin(2*math.pi*(790+n*70)*t)*math.exp(-t/.022)))
for n in range(3):
    save(f'impact{n}',synth(.075,lambda t,i:.7*sample(wood,int(i*(.9+n*.08)))*math.exp(-t/.022)+.18*math.sin(2*math.pi*(145+n*23)*t)*math.exp(-t/.025)))
save('crystal',synth(.105,lambda t,i:.75*sample(glass,i)*math.exp(-t/.03)+.18*math.sin(2*math.pi*2093*t)*math.exp(-t/.035)))
save('star',synth(.36,lambda t,i:.55*sample(glass,i)*math.exp(-t/.06)+(.35*math.sin(2*math.pi*1567.98*t)+.24*math.sin(2*math.pi*2093*t)+.12*math.sin(2*math.pi*2637*t))*math.exp(-t/.10)))
for name,base in [('upgrade',440),('quota',523.25),('special',392)]:
    def chord(t,i):
        return sum(math.sin(2*math.pi*base*ratio*(t-delay))*math.exp(-(t-delay)/.085) for ratio,delay in [(1,0),(1.25,.035),(1.5,.07)] if t>=delay)
    save(name,synth(.32,chord))
for name,frequencies in [('absorb',[43,67,89,113,137,173]),('rolling',[127,193,257,337,419,547,691])]:
    phases=[rng.random()*math.pi*2 for _ in frequencies]
    save(name,synth(1,lambda t,i:sum(math.sin(2*math.pi*f*t+phase)/(1+j*.6) for j,(f,phase) in enumerate(zip(frequencies,phases)))*(1+.08*math.cos(2*math.pi*2*t))),loop=True)
# A quiet shared surface texture, not one loop per ball. Banded original noise
# with tiny CC0 wood grains, crossfaded into a seamless loop.
low = slow = 0.0
texture = []
for i in range(RATE * 2):
    low = low*.78 + rng.uniform(-1,1)*.22
    slow = slow*.99 + low*.01
    texture.append((low-slow)*.8 + sample(wood, i % (RATE//8))*.035)
texture = texture[RATE:]
fade = 256
seam = [texture[-fade+i]*(1-i/(fade-1)) + texture[i]*i/(fade-1) for i in range(fade)]
save('rolling', texture[fade:-fade] + seam, loop=True)
# Isolated receipts reuse a short fragment of the existing ascending cascade.
# A single preloaded voice keeps the same voice/priority limits under load.
cascade = [0.0] * round(RATE * .35)
for note in range(3):
    with wave.open(str(OUT / f'coin{note}.wav'), 'rb') as w:
        pcm = array.array('h'); pcm.frombytes(w.readframes(w.getnframes()))
    offset = round(note * .08 * RATE)
    for i, value in enumerate(pcm):
        if offset + i < len(cascade): cascade[offset + i] += value / 32767
save('coincascade', cascade)
(ROOT/'assets/audio/manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(f'{len(manifest)} sounds generated; peak <=0.62 PCM, mono {RATE} Hz')

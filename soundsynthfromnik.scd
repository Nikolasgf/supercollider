//código desenvolvido no âmbito da disciplina de
//Síntese e Processamento de Sinais de Áudio
//no Mestrado em Produção e Tecnologias do Som
// ULHT - Lisboa

//Nikolas Gomes - 2020
//n.ferranddis@gmail.com
//www.nikolasgomes.com.br
//github.com/Nikolasgf

//use it as you wish,
//but don't forget to
//keep this header

//this code uses the mrmr app
//to control the balance between
//left and right, control the pitch
//and trigger the synthesizer

//you have to change the addres at the OSCdef lines


(
s.quit;//make sure that the server is off
s.options.memSize = 128 * 1024;
s.options.device_("Soundflower (2ch)");//choose your audio device here
s.boot;

//OSCFunc.trace;  //so you can confirm that OSC is coming from mrmr

//r = Server(\localhost,NetAddr("169.254.173.210",57110), o); //to use with external server

s.waitForBoot{
	//SYNTHESIZER
	SynthDef.new(\iter, {
		arg freq = 40, dur = 5, mul = 1,
		spd = 1, pit = 1, bal = 0,
		sum = 0, gate=0, mult = 1,
		out = 16;
		var temp;
		10.do{
			temp = VarSaw.ar(
				freq * {Rand(0.99,1.01)},
				{Rand(0.0,1.0)},
				{ExpRand(0.005, 0.05)}
			);
			sum = sum + temp;
		};
		sum = PitchShift.ar(sum,1, pit);
		sum = [
			PitchShift.ar(sum, 0.5, 4)*0.1,
			PitchShift.ar(sum, 0.5, 3)*0.4,
			PitchShift.ar(sum, 0.5, 2)*0.5,
			PitchShift.ar(sum, 0.5, 1)*1,
			PitchShift.ar(sum, 0.5, 2)*0.5,
			PitchShift.ar(sum, 0.5, 3)*0.4,
			PitchShift.ar(sum, 0.5, 4)*0.1,
		];
		sum = Splay.ar(sum) * 0.4;
		sum = sum * mul;
		sum = Balance2.ar(sum[0], sum[1], bal);
		sum = sum * gate;
		Out.ar(out, sum);
		//}).send(r);//to external server
	}).send;//to server in this machine

	//EQUALIZER
	SynthDef.new(\eq12band, {
		arg in = 16, out=18, rq=0.5,
		fq50=50, gain50=0,
		fq100=100, gain100=0,
		fq200=200, gain200=0,
		fq400=400, gain400=0,
		fq800=800, gain800=0,
		fq1600=1600, gain1600=0,
		fq3200=3200, gain3200=0,
		fq4800=4800, gain4800=0,
		fq6400=6400, gain6400=0,
		fq9600=9600, gain9600=0,
		fq12800=12800, gain12800=0,
		fq16000=16000, gain16000=0;
		var sig;
		sig = In.ar(in,2);
		sig = BPeakEQ.ar(sig, fq50,rq,gain50);
		sig = BPeakEQ.ar(sig, fq100,rq,gain100);
		sig = BPeakEQ.ar(sig, fq200,rq,gain200);
		sig = BPeakEQ.ar(sig, fq400,rq,gain400);
		sig = BPeakEQ.ar(sig, fq800,rq,gain800);
		sig = BPeakEQ.ar(sig, fq1600,rq,gain1600);
		sig = BPeakEQ.ar(sig, fq3200,rq,gain3200);
		sig = BPeakEQ.ar(sig, fq4800,rq,gain4800);
		sig = BPeakEQ.ar(sig, fq6400,rq,gain6400);
		sig = BPeakEQ.ar(sig, fq9600,rq,gain9600);
		sig = BPeakEQ.ar(sig, fq12800,rq,gain12800);
		sig = BPeakEQ.ar(sig, fq16000,rq,gain16000);
		Out.ar(out, sig);
		//}).send(r);//to external server
	}).send;

	//REVERB
	SynthDef.new(\reverb, {
		arg in = 18, out = 20,
		mix = 0.33, room = 0.5,
		damp = 0, mul = 1;
		var sig;
		sig = In.ar(in,2);
		sig = FreeVerb.ar(sig,mix,room,damp,mul);
		Out.ar(out, sig);
		//}).send(r);//to external server
	}).send;


	//DELAY
	SynthDef.new(\delay, {
		arg in = 20, out = 22,
		dry = 1, wet = 1,
		mdt = 1, dlt = 1, dlf=0;
		var sig;
		sig = In.ar(in,2);
		sig = SwitchDelay.ar(sig, dry, wet,dlt, dlf, mdt);
		Out.ar(out,sig);
		//}).send(r);//to external server
	}).send;

	//LIMITER
	SynthDef.new(\limiter, {
		arg in = 22, out = 0,
		lvl = 0.9, dur = 0.01;
		var sig;
		sig = In.ar(in,2);
		sig = Limiter.ar(sig, lvl, dur);
		Out.ar(out, sig);
		//}).send(r);//to external serve
	}).send;

	//wait for server to "mount" the synthdef's
	s.sync;


//use these if you running the server on this machine
~lim = Synth.new(\limiter, [\lvl, 0.19], s);
~dly = Synth.new(\delay, [\dlt, 0.5],s);
~rev = Synth.new(\reverb,[\mul, 0.8],s);
e = Synth.new(\eq12band,[\rq,0.5],s);
a = Synth.new(\iter, [\gate,0],s);


//use these if you runing an external server
// (
// ~lim = Synth.new(\limiter, [\lvl, 0.19], r);
// //~dly = Synth.new(\delay, [\dlt, 0.5],r);
// ~rev = Synth.new(\reverb,[\mul, 0.8],r);
// e = Synth.new(\eq12band,[\rq,0.5],r);
// a = Synth.new(\iter, [\gate,0],r);
// )

//to listen to incoming OSC msg from the mrmr app
y = OSCdef(\phonepit, { |m| a.set(\pit, m[1].linlin(0,1,2,0.1))},'/mrmr/accelerometerY/0/iPhone-de-Nikolas');
x = OSCdef(\phonebal, { |n| a.set(\bal, n[1].linlin(0,1,1,-1))},'/mrmr/accelerometerX/0/iPhone-de-Nikolas');
d = OSCdef(\onoff, { |n| a.set(\gate, n[1])},'/mrmr/pushbutton/1/iPhone-de-Nikolas');

//GUI for the controls
s.freqscope;
w = Window.new(\rack, Rect.new(700,50,800,500)).front;
//eq sliders
EZSlider.new(w,Rect(15,10,25,350)," 50", ControlSpec.new(-18,18,\lin,0,0,\db), { |ez| e.set(\gain50, ez.value)}, 0,false, 60,45,0,20,\vert);
EZSlider.new(w,Rect(45,10,25,350),\100, ControlSpec.new(-18,18,\lin,0,0,\db), { |ez| e.set(\gain100, ez.value)}, 0,false, 60,45,0,20,\vert);
EZSlider.new(w,Rect(75,10,25,350),\200, ControlSpec.new(-18,18,\lin,0,0,\db), { |ez| e.set(\gain200, ez.value)}, 0,false, 60,45,0,20,\vert);
EZSlider.new(w,Rect(105,10,25,350),\400, ControlSpec.new(-18,18,\lin,0,0,\db), { |ez| e.set(\gain400, ez.value)}, 0,false, 60,45,0,20,\vert);
EZSlider.new(w,Rect(135,10,25,350),\800, ControlSpec.new(-18,18,\lin,0,0,\db), { |ez| e.set(\gain800, ez.value)}, 0,false, 60,45,0,20,\vert);
EZSlider.new(w,Rect(165,10,25,350)," 1.6", ControlSpec.new(-18,18,\lin,0,0,\db), { |ez| e.set(\gain1600, ez.value)}, 0,false, 60,45,0,20,\vert);
EZSlider.new(w,Rect(195,10,25,350)," 3.2", ControlSpec.new(-18,18,\lin,0,0,\db), { |ez| e.set(\gain3200, ez.value)}, 0,false, 60,45,0,20,\vert);
EZSlider.new(w,Rect(225,10,25,350)," 4.8", ControlSpec.new(-18,18,\lin,0,0,\db), { |ez| e.set(\gain4800, ez.value)}, 0,false, 60,45,0,20,\vert);
EZSlider.new(w,Rect(255,10,25,350)," 6.4", ControlSpec.new(-18,18,\lin,0,0,\db), { |ez| e.set(\gain6400, ez.value)}, 0,false, 60,45,0,20,\vert);
EZSlider.new(w,Rect(285,10,25,350)," 9.6", ControlSpec.new(-18,18,\lin,0,0,\db), { |ez| e.set(\gain9600, ez.value)}, 0,false, 60,45,0,20,\vert);
EZSlider.new(w,Rect(315,10,25,350),"12.8", ControlSpec.new(-18,18,\lin,0,0,\db), { |ez| e.set(\gain12800, ez.value)}, 0,false, 60,45,0,20,\vert);
EZSlider.new(w,Rect(345,10,25,350),"16.0", ControlSpec.new(-18,18,\lin,0,0,\db), { |ez| e.set(\gain16000, ez.value)}, 0,false, 60,45,0,20,\vert);
//eq Q knob
EZKnob.new(w,Rect(10,370,100,100),"Q",ControlSpec.new(0,1,\lin,0,0.5), { |ez| e.set(\rq, ez.value)});

//REVERB CONTROLS
EZSlider.new(w,Rect(400,10,25,350),"mix", ControlSpec.new(0,1,\lin,0,0), { |ez| ~rev.set(\mix, ez.value)}, 0.5,false, 60,45,0,20,\vert);
EZSlider.new(w,Rect(430,10,25,350),"rom", ControlSpec.new(0,1,\lin,0,0), { |ez| ~rev.set(\room, ez.value)}, 0.5,false, 60,45,0,20,\vert);
EZSlider.new(w,Rect(460,10,25,350),"dmp", ControlSpec.new(0,1,\lin,0,0), { |ez| ~rev.set(\damp, ez.value)}, 0.5,false, 60,45,0,20,\vert);
EZSlider.new(w,Rect(490,10,25,350),"vol", ControlSpec.new(-60,6,\lin,0,0,\db), { |ez| ~rev.set(\mul, ez.value.dbamp)}, 0,false, 60,45,0,20,\vert);

//DELAY CONTROLS
EZSlider.new(w,Rect(540,10,25,350),"dry", ControlSpec.new(-60,6,\lin,0,0,\db), { |ez| ~dly.set(\dry, ez.value.dbamp)}, 0,false, 60,45,0,20,\vert);
EZSlider.new(w,Rect(570,10,25,350),"wet", ControlSpec.new(-60,6,\lin,0,0,\db), { |ez| ~dly.set(\wet, ez.value.dbamp)}, 0,false, 60,45,0,20,\vert);
EZSlider.new(w,Rect(600,10,25,350),"dlt", ControlSpec.new(0,3,\lin,0,0), { |ez| ~dly.set(\dlt, ez.value)}, 0.5,false, 60,45,0,20,\vert);
EZSlider.new(w,Rect(630,10,25,350),"dlf", ControlSpec.new(0,1,\lin,0,0), { |ez| ~dly.set(\dlf, ez.value)}, 0.5,false, 60,45,0,20,\vert);
EZSlider.new(w,Rect(660,10,25,350),"mdt", ControlSpec.new(0,40,\lin,0,0), { |ez| ~dly.set(\mdt, ez.value)}, 0.5,false, 60,45,0,20,\vert);

//limiter controls
EZSlider.new(w,Rect(700,10,25,350),"lvl", ControlSpec.new(-60,6,\lin,0,0,\db), { |ez| ~lim.set(\lvl, ez.value.dbamp)}, 0,false, 60,45,0,20,\vert);
EZSlider.new(w,Rect(730,10,25,350),"look", ControlSpec.new(0,5,\lin,0,0,\db), { |ez| ~lim.set(\dur, ez.value/10)}, 0.1,false, 60,45,0,20,\vert);
//when u press cmd + . the gui closes
CmdPeriod.doOnce({if(w.isClosed.not, {w.close})});
}
)

//hope you had fun!

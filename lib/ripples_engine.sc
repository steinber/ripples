// a few ripples
// based on Sines engine
// https://github.com/catfact/zebra/blob/master/lib/Engine_Zsins.sc
// thank you zebra

Engine_Ripples : CroneEngine {
  classvar num;
  var <synth;

  *initClass {  num = 16; }

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    var server = Crone.server;
    var def = SynthDef.new(\rip, {
      arg out, vol=0.0, hz=220, hz_lag=0.005, vol_lag=0.1,
        env_bias=0.0, amp_atk=0.001, amp_rel=0.05,
        pan=0.0, pan_lag=0.005, mul=1, modPartial=1, carPartial=1, fm_index=1.0, sample_rate=48000, bit_depth=24;
      var mod, car, car_decimate, amp_, hz_, pan_, vol_;
      //amp_ = EnvGen.ar(Env.circle([0, 1, 0], [amp_atk, amp_rel, 0.001]), levelBias: env_bias);
      hz_ = Lag.ar(K2A.ar(hz), hz_lag);
      pan_ = Lag.ar(K2A.ar(pan), pan_lag);
      vol_ = vol;
      //vol_ = Lag.ar(K2A.ar(vol), vol_lag);
      //could also try replacing with https://doc.sccode.org/Classes/PMOsc.html
      mod = SinOsc.ar(hz_ * modPartial, 0, hz_ * fm_index * LFNoise1.kr(5.reciprocal).abs);
      car = SinOsc.ar(hz_ * carPartial + mod, 0, mul);
      car_decimate = Decimator.ar(car, sample_rate, bit_depth, 1.0, 0);
      //Out.ar(out, Pan2.ar(car_decimate * amp_ * vol, pan_));
      Out.ar(out, Pan2.ar(car_decimate * vol, pan_));
    });
    def.send(server);
    server.sync;

    synth = Array.fill(num, { Synth.new(\rip, [\out, context.out_b], target: context.xg) });

    #[\hz, \vol, \env_bias, \pan, \amp_atk, \amp_rel, \hz_lag, \pan_lag, \vol_lag, \fm_index].do({
      arg name;
      this.addCommand(name, "if", {
        arg msg;
        var i = msg[1];
        synth[i].set(name, msg[2]);
      });
    });

    #[\sample_rate, \bit_depth].do({
      arg name;
      this.addCommand(name, "ii", {
        arg msg;
        var i = msg[1];
        synth[i].set(name, msg[2]);
      });
    });

  }

  free {
    synth.do({ |syn| syn.free; });
  }
}



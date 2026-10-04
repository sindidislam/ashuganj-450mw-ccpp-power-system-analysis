function [packedPhasors,waveformRMS,valid,state] = phase6_measurement_step(samples,time,state)
%PHASE6_MEASUREMENT_STEP One sample of a 20 ms, fixed-50 Hz measurement window.
% [P,R,VALID,S] = phase6_measurement_step(X,T,S) accepts 114 real instantaneous
% values: 19 sensor groups of [Va Vb Vc Ia Ib Ic]. Pass [] for S on reset.
% P is 228 real doubles, grouped by sensor as
% [Re(Vabc) Im(Vabc) Re(Iabc) Im(Iabc)]; R is 114 full-waveform RMS values in
% input order. Both outputs are zero until all 20 samples have been acquired.
%
% The complex RMS phasor uses a COSINE reference:
%   X = sqrt(2)/20 * sum(x(t_k)*exp(-1i*2*pi*50*t_k)).
% Thus sqrt(2)*A*cos(2*pi*50*t+phi) returns A*exp(1i*phi). Each sample uses its
% absolute simulation time T, synchronizing every sensor and avoiding a phase
% rotation when the sliding window advances. Nominal sample interval is 1 ms.
% R = sqrt(mean(x.^2)) retains DC and harmonics; P extracts only the 50 Hz bin.
%
% S is an entirely numeric 2322-double ring buffer: 114*20 raw samples,
% 20 cosines, 20 sines, last-written position, and sample count (saturated at
% 20). There is no persistent/global state. This helper returns the updated
% window immediately. phase6_measurement_sfun presents it on the NEXT sample
% hit, producing one explicit 1 ms Update-to-Outputs delay.

sampleCount=20; channelCount=114;
if isempty(state), state=zeros(2322,1); end
history=reshape(state(1:2280),channelCount,sampleCount);
cosines=state(2281:2300);
sines=state(2301:2320);
position=mod(state(2321),sampleCount)+1;
count=min(state(2322)+1,sampleCount);
history(:,position)=samples(:);
phase=2*pi*50*time;
cosines(position)=cos(phase);
sines(position)=sin(phase);
state=[history(:);cosines(:);sines(:);position;count];

valid=double(count==sampleCount);
packedPhasors=zeros(228,1);
waveformRMS=zeros(channelCount,1);
if ~valid, return; end

realPart=(sqrt(2)/sampleCount)*(history*cosines(:));
imagPart=-(sqrt(2)/sampleCount)*(history*sines(:));
realBySensor=reshape(realPart,6,19);
imagBySensor=reshape(imagPart,6,19);
packedPhasors=reshape([realBySensor(1:3,:);imagBySensor(1:3,:); ...
    realBySensor(4:6,:);imagBySensor(4:6,:)],228,1);
waveformRMS=sqrt(sum(history.^2,2)/sampleCount);
end

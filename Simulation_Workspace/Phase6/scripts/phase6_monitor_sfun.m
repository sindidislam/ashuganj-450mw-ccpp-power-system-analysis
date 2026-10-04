function phase6_monitor_sfun(b)
% Actual electrical phasors, machine states, relay and DC diagnostics.
b.NumDialogPrms=0;b.NumInputPorts=5;b.NumOutputPorts=1;
b.SetPreCompInpPortInfoToDynamic;b.SetPreCompOutPortInfoToDynamic;
d=[228 4 43 6 12];
for k=1:5,b.InputPort(k).Dimensions=d(k);b.InputPort(k).DirectFeedthrough=true;end
b.OutputPort(1).Dimensions=24;b.SampleTimes=[.001 0];
b.RegBlockMethod('Outputs',@output);
end
function output(b)
p=reshape(b.InputPort(1).Data,12,19).';
v=complex(p(:,1:3),p(:,4:6));i=complex(p(:,7:9),p(:,10:12));
m=b.InputPort(2).Data;r=b.InputPort(3).Data;br=b.InputPort(4).Data;dc=b.InputPort(5).Data;
s=sum(v.*conj(i),2)/1e6;
vll=sqrt(mean(abs(v).^2,2))*sqrt(3)/1000;
im=max(abs(i),[],2)/1000;
b.OutputPort(1).Data=[real(s(1));imag(s(1));vll(1);im(1);50*m(1);m(1);m(2); ...
    im(4);vll(5);im(11);max(im(13:19));double(any(r(1:7))); ...
    double(any(r(8:14)));br(1);br(2);br(3);br(4);dc(1);dc(5)*100;dc(6); ...
    vll(10);real(s(11));imag(s(11));double(any(dc(7:10)))];
end

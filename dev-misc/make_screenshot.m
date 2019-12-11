f = figure('Units','inches','Position',[3 3 2 1.5]);

w = animatedPNGWriter('animatedPNGWriter-screenshot.png');

h = animatedline('LineWidth',1.5,'Color',lines(1));
axis([0,4*pi,-1,1])
numpoints = 10000;
x = linspace(0,4*pi,numpoints);
y = sin(x);
for k = 1:500:numpoints-499
    xvec = x(k:k+499);
    yvec = y(k:k+499);
    addpoints(h,xvec,yvec)
    drawnow
    addframe(w,print('-r150','-RGBImage'));
end

finish(w);
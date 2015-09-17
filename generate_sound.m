%%
% Machine Vision Project
%
% Author: Colin Power
% Email: cp1372@mun.ca
% Description: Small script that is able to generate .wav tone using a
% given frequency. Was just a test in sound generation.

t=linspace(0, 2, 20000);
y=sin(262*2*pi*t);
sound(y, 10000);
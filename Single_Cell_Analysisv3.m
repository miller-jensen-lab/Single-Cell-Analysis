%Single_Cell_Analysis main script
%Calls Loading GUI and all other functions from there
clear;clc;
fullname=mfilename('fullpath');
[pathstr,name,ext]=fileparts(fullname);
addpath(genpath(pathstr));
clear;
% wrongfull=which(Single_Cell_Analysis.m);
% [wrongpath,~,~]=fileparts(wrongfull);
% rmpath(wrongpath);
Loading_GUI

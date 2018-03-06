%Read fcs files from cyt and get %s
[fcsdata fcsother] = fca_readfcs
binarydat=fcsdata(:,4:18)>asinh(1/0.8);
signal_names=vertcat({fcsother.par(4:18).name2});
per_on=round((sum(binarydat)/length(binarydat))*100,2);

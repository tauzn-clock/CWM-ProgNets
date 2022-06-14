%Plot CPF
%M = readtable("ping_10ms.csv","ReadVariableNames",false);
%M = M{:,:};
%cdfplot(M)

%Plot Time
M = [958 941 942 941 940 941 946 942 936 947];
t = [1 2 3 4 5 6 7 8 9 10];
plot(t,M)


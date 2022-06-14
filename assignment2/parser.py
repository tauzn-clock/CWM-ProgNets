name = "ping_0.1ms"

f = open(name+".log", "r")

store = []

for line in f:
	tmp = line.split("=")
	if len(tmp) == 4: store.append(tmp[3][:5])


f = open(name+".csv", "w")

for i in store:
	f.write(i+",\n")

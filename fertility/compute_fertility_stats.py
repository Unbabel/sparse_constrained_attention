import sys

f = open(sys.argv[1])
counts = [0 for i in range(100)]
for line in f:
    fields = line.rstrip('\n').split()
    ferts = [int(field) for field in fields]
    for fert in ferts:
        counts[fert] += 1
f.close()

for fert in range(len(counts)):
    if counts[fert]:
        print fert, counts[fert], '%f%%' % (counts[fert] / float(sum(counts)))

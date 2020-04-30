#/usr/bin/env python
#-*- coding:utf-8 -*-
import sys

li=[]
# ip = raw_input("please input ip:")
print(sys.argv[1]) 
ip = sys.argv[1]
print("ip=" + ip)

ip = ip.split(".")
length = len(ip)
if length != 4:
    print 'this string is not a ip address'
    sys.exit()
try:
    for i in range(0,4):
        li.append(int(ip[i]))
except:
    print 'not ip address'
    sys.exit()

for i in li:
    if isinstance(i,int):
        continue
    else:
        print 'this string is not a ip address'
        sys.exit()
for j in li:
    if  j < 0 or j > 255:
        print 'this string is not a validate ip address' + "! post:" + str(li) + ", value:" + str(j)
        sys.exit()
print 'IsIPAddress'
# sys.exit(0)

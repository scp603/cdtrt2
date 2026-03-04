import sys

func = ""
if len(sys.argv) == 2:
    func = sys.argv[1]
else:
    func = input("string: ")

def printStrFunc(func):
    "print function in string format"
    for element in func:
        print("L'", end="")
        print(element, end="")
        print("', ", end="")

print("wchar_t s",end="")
print(func.replace(".","_"),end="")
print("[] = { ",end="")
printStrFunc(func)
print("0x0 ",end="")
print("};\n",end="")
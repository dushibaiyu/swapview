#!/usr/bin/dmd -run

import std.stdio, std.file, std.path, std.string, std.conv, std.math, std.algorithm.sorting;

string filesize(double size){
    enum units = "KMGT";
    double left = size.fabs();
    int unit = -1;

    while(left > 1100 && unit < 3){
        left /=1024;
        unit += 1;
    }

    if(unit == -1){
        return format("%dB", to!int(size));
    }else{
        if(size < 0)
            left = -left;
        return format("%.1f%siB", left, units[unit]);
    }
}

string getcmdln(string pid){
    auto ret = cast(ubyte[])read(format("/proc/%s/cmdline", pid));
    if(ret[$-1] == '\0')
        ret = ret[0..($-1)];
        
    foreach(ref ubyte c; ret){
        if(c=='\0') c=' ';
    }
    
    return cast(string) ret;
}

double checkswap(string pid){
    double size = 0;
    File file = File(format("/proc/%s/smaps", pid), "r");
    while (!file.eof()){
        string line = chomp(file.readln());
        if(!line.indexOf("Swap:")){
            size += to!int(line.split()[1]);
        }
    }
    return size * 1024 ;
}

struct SwapInfo
{
    int pid;
    double size;
    string comm;
}

SwapInfo[] getSwap(){
    SwapInfo[] ret;
    auto dirEns = dirEntries("/proc", SpanMode.shallow);
    foreach(DirEntry dirs; dirEns){
        string pid = baseName(dirs.name);
        if(pid.isNumeric()){
            try{
                double size = checkswap(pid);
                if(size)
                    ret ~= SwapInfo(to!int(pid), size, getcmdln(pid));
            }catch(Exception e){
                writeln(e.toString());
            }
        }
    }
    sort!"a.size < b.size"(ret);
    return ret;
}


void main(){
    enum m = "%5s %9s %s";
    double total=0;
    auto result=getSwap();
    writeln(format(m , "PID", "SWAP", "COMMAND"));
    foreach(SwapInfo item; result){
        total += item.size;
        writeln(format(m , item.pid, filesize(item.size), item.comm));
    }
    writeln(format("Total: %8s", filesize(total)));
}

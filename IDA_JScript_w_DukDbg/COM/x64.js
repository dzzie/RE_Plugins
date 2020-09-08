/*
    Function toHex(str1)
	Function Add(str1,val2)
	Function Subtract(str1,val2)
*/

function x64Class(){

    this.hInst = 0
	
	this.toHex = function(str1){
		return resolver('x64.toHex', arguments.length, 0, str1, 0);
	}
	
	this.add = function(str1, str2){
		return resolver('x64.Add', arguments.length, 0, str1, str2);
	}
	
	this.subtract = function(str1, str2){
		return resolver('x64.Subtract', arguments.length, 0, str1, str2);
	}
	

}

var x64 = new x64Class()


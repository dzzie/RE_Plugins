/*
		Sub AddItem(Item As variant, Index as integer)
		Property get Enabled As Boolean
		Property let Enabled As Boolean
		Property get ListCount As Integer
		Sub Clear()
*/

function listClass(){

	this.hInst = 0

	this.AddItem = function(Item, Index){
		return resolver('list.AddItem', arguments.length, this.hInst, Item, Index);
	}

	this.Clear = function(){
		return resolver('list.Clear', arguments.length, this.hInst);
	}

}

listClass.prototype = {
	get Enabled(){
		return resolver('list.Enabled.get', 0, this.hInst);
	},

	set Enabled(val){
		return resolver('list.Enabled.let', 1, this.hInst, val);
	},

	get ListCount(){
		return resolver('list.ListCount.get', 0, this.hInst);
	}
}

var list = new listClass()
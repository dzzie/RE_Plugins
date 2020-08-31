/* bindings for a vb textbox control

#requires hInst

	property get Text as string
	property let Text as string 

*/

function textboxClass(){
	this.hInst=0;
}

textboxClass.prototype = {
	get Text (){
		return resolver("textbox.Text.get", 0, this.hInst); 	
	},
	set Text (val){
		resolver("textbox.Text.let", 1, this.hInst, val); 
	}
};

//this next line allows you to use a AddObject(txtMyTextBox, "textbox") directly..
var textbox = new textboxClass();
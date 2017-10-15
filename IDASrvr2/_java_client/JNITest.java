
public class JNITest {

	public native int InitHwnd();
	public native String SendCMDRecvText(String msg);
	public native int SendCMDRecvInt(String msg);
	public native void SendCMD(String msg); 
	public native void Shutdown(); 
	
	static {
		System.loadLibrary("copydata");
	}   
	
	private int hwnd=0;
	
	public static void main(String[] args) {
		
		JNITest t = new JNITest();
		t.hwnd = t.InitHwnd();
		
		if(t.hwnd==0){
			System.out.println("JAVA: Init failed to connect to IDA or create command window.");
			t.Shutdown();
			return;
		}
		
		String loadedFile = t.SendCMDRecvText("loadedfile:"+t.hwnd);
		System.out.println("JAVA: Loaded File:"+loadedFile);
		
		int numFuncs = t.SendCMDRecvInt("numfuncs:"+t.hwnd);
		System.out.println("JAVA: Number of functions: "+numFuncs);
		
		System.out.println("JAVA: Jumping to 0x401000");
		t.SendCMD("jmp:"+0x401000);
		
		t.Shutdown();
		
	}

}

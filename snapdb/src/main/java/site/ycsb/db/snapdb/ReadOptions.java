package site.ycsb.db.snapdb;

/**
 * Concrete ReadOptions implementation.
 */
public class ReadOptions {

  static {
    System.loadLibrary("snapdbjni"); // Load native library
  }
  private long cppPtr;
  // Declare an instance native methods
  protected native void init(byte[] key, int keylen);
  protected native void destory();
}

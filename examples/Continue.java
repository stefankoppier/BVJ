class Main {
    public static void main(String[] argv) {
        int[] array = { 0, 1, 2 };
        int i = 0;

        a: while (true) {
            while (i < array.length) {
                if (true) {
                    assert true;
                } else {
                    continue a;
                }
                i++;
            }
        }
    }
}
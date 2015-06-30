package luci;

import org.junit.*;
import static org.junit.Assert.*;

public class HikerTest {

    @Test
    public void lifeTheUniverseAndEverything() {
        int expected = 42;
        int actual = Hiker.answer();
        assertEquals(expected, actual);
    }
}

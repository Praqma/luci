package net.praqma.luci.utils

import net.praqma.luci.utils.ExternalCommand
import org.junit.Test


class ExternalCommandTest {

    @Test
    void testExecute() {
        ExternalCommand cmd = new ExternalCommand()
        int exitCode = cmd.execute(["wc", "-l"], null) { OutputStream stream ->
            stream.withPrintWriter { PrintWriter writer ->
                writer.println("one")
                writer.println("two")
            }
            stream.close()
        }
        assert exitCode == 0
    }
}

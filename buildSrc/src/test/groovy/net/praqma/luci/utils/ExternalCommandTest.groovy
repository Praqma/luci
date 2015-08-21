package net.praqma.luci.utils

import net.praqma.luci.utils.ExternalCommand
import org.junit.Test


class ExternalCommandTest {

    @Test
    void testExecute() {
        ExternalCommand cmd = new ExternalCommand()
        Closure input = { OutputStream os ->
            os << "HelloWorld\n"
        }
        Closure output = { InputStream is ->
            assert is.readLines()[0] == '11'
        }
        int exitCode = cmd.execute('sh', '-c', 'read x ; echo $x | wc -c', in: input, out: output)
        assert exitCode == 0
    }
}

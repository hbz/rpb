package rpb;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.antlr.runtime.RecognitionException;
import org.apache.log4j.Logger;
import org.metafacture.commons.ResourceUtil;
import org.metafacture.flux.FluxCompiler;
import org.metafacture.flux.parser.FluxProgramm;

/**
 * ETL main for Allegro export data. See README for instructions on running.
 */
public class ETL {
    private static final Logger LOG = Logger.getLogger(ETL.class);
    private static final Pattern VAR_PATTERN = Pattern.compile("([^=]*)=(.*)");
    private static final String SCRIPT_HOME = "FLUX_DIR";

    public static void main(final String[] args) throws FileNotFoundException, RecognitionException, IOException {
        LOG.info("Process args: " + Arrays.asList(args));
        if (args.length < (1)) {
            FluxProgramm.printHelp(System.out);
            System.exit(2);
        } else {
            final File fluxFile = new File(args[0]);
            if (!fluxFile.exists()) {
                System.err.println("File not found: " + args[0]);
                System.exit(1);
                return;
            }
            final Map<String, String> vars = new HashMap<String, String>();
            vars.put(SCRIPT_HOME, fluxFile.getAbsoluteFile().getParent() + System.getProperty("file.separator"));
            for (int i = 1; i < args.length; ++i) {
                final Matcher matcher = VAR_PATTERN.matcher(args[i]);
                if (!matcher.find()) {
                    FluxProgramm.printHelp(System.err);
                    return;
                }
                vars.put(matcher.group(1), matcher.group(2));
            }
            FluxCompiler.compile(ResourceUtil.getStream(fluxFile), vars).start();
        }
    }
}

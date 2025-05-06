/* Copyright 2014, 2022 Fabian Steeg, hbz. Licensed under the GPLv2 */

package rpb;

import static org.fest.assertions.Assertions.assertThat;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;

import org.antlr.runtime.RecognitionException;
import org.junit.Test;
import org.metafacture.framework.StreamReceiver;
import org.mockito.Mock;

/**
 * Tests for class {@link ETL}.
 *
 * @author Fabian Steeg
 * 
 */
public class EtlTest {

    @Mock
    private StreamReceiver streamReceiver;

    @Test
    public void runMain() throws FileNotFoundException, RecognitionException, IOException {
        File output = new File("conf/output/test-output-0.json");
        output.delete();
        assertThat(output).as("test output").doesNotExist();
        ETL.main(new String[] { "conf/rpb-test-titel-to-strapi.flux" });
        ETL.main(new String[] { "conf/rpb-test-titel-to-lobid.flux" });
        assertThat(output).as("test output").exists();
    }

}

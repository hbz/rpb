/* Copyright 2022 Fabian Steeg, hbz. Licensed under the GPLv2 */

package rpb;

import static org.hamcrest.CoreMatchers.startsWith;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.verifyZeroInteractions;

import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.ExpectedException;
import org.metafacture.framework.MetafactureException;
import org.metafacture.framework.StreamReceiver;
import org.mockito.InOrder;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.exceptions.base.MockitoAssertionError;
import org.mockito.junit.MockitoJUnit;
import org.mockito.junit.MockitoRule;

/**
 * Tests for class {@link Decode}.
 *
 * @author Fabian Steeg
 *
 */
public final class DecodeTest {

    @Rule
    public MockitoRule mockitoRule = MockitoJUnit.rule();

    @Rule
    public ExpectedException exception = ExpectedException.none();

    @Mock
    private StreamReceiver receiver;

    private Decode decode;

    @Before
    public void init() {
        decode = new Decode();
        decode.setReceiver(receiver);
    }

    public void processEmptyStrings() {
        decode.process("");
        verifyZeroInteractions(receiver);
    }

    @Test
    public void processRecord() {
        test("[/]#00 123[/]#20 abc[/]#983HT011020818[/]", () -> {
            final InOrder ordered = inOrder(receiver);
            ordered.verify(receiver).startRecord("123");
            ordered.verify(receiver).literal("f00_", "123");
            ordered.verify(receiver).literal("f20_", "abc");
            ordered.verify(receiver).literal("f983", "HT011020818");
            ordered.verify(receiver).endRecord();
            ordered.verifyNoMoreInteractions();
        });
    }

    @Test
    public void processRecordWithMultipleVolumes() {
       // 'sm' & 'sbd' in '#36 ' -> treat as MultiVolumeBook with their own titles
        test("[/]#00 929t124030[/]#20 Deutsche Binnenwasserstraßen[/]#36 sm[/]"
                + "#01 6/2022[/]#36 sbd[/]#20 Der Rhein - Rheinfelden bis Koblenz[/]"
                + "#01 7. Band 2022[/]#20 Der Rhein - Koblenz bis Tolkamer[/]"
                + "#01 Nachgewiesen 2007 -[/]#20 [/]"
                + "#01 Nachgewiesen 2008 -[/]",
                () -> {
                    final InOrder ordered = inOrder(receiver);
                    ordered.verify(receiver).startRecord("929t124030");
                    ordered.verify(receiver).literal("f00_", "929t124030");
                    ordered.verify(receiver).literal("f20_", "Deutsche Binnenwasserstraßen");
                    ordered.verify(receiver).literal("f36_", "sm");
                    ordered.verify(receiver).literal("f36t", "MultiVolumeBook");
                    ordered.verify(receiver).endRecord();
                    ordered.verify(receiver).startRecord("929t124030b1");
                    ordered.verify(receiver).literal("f00_", "929t124030b1");
                    ordered.verify(receiver).literal("f20ü", "Deutsche Binnenwasserstraßen");
                    ordered.verify(receiver).literal("f20_", "Deutsche Binnenwasserstraßen : 6/2022");
                    ordered.verify(receiver).literal("f01_", "6/2022");
                    ordered.verify(receiver).literal("f36_", "sbd");
                    ordered.verify(receiver).literal("f20_", "Der Rhein - Rheinfelden bis Koblenz");
                    ordered.verify(receiver).endRecord();
                    ordered.verify(receiver).startRecord("929t124030b2");
                    ordered.verify(receiver).literal("f00_", "929t124030b2");
                    ordered.verify(receiver).literal("f20ü", "Deutsche Binnenwasserstraßen");
                    ordered.verify(receiver).literal("f20_", "Deutsche Binnenwasserstraßen : 7. Band 2022");
                    ordered.verify(receiver).literal("f01_", "7. Band 2022");
                    ordered.verify(receiver).literal("f20_", "Der Rhein - Koblenz bis Tolkamer");
                    ordered.verify(receiver).endRecord();
                    ordered.verify(receiver).startRecord("929t124030b3");
                    ordered.verify(receiver).literal("f00_", "929t124030b3");
                    ordered.verify(receiver).literal("f20ü", "Deutsche Binnenwasserstraßen");
                    ordered.verify(receiver).literal("f20_", "Deutsche Binnenwasserstraßen : Nachgewiesen 2007 -");
                    ordered.verify(receiver).literal("f01_", "Nachgewiesen 2007 -");
                    ordered.verify(receiver).literal("f20_", "");
                    ordered.verify(receiver).endRecord();
                    ordered.verify(receiver).startRecord("929t124030b4");
                    ordered.verify(receiver).literal("f00_", "929t124030b4");
                    ordered.verify(receiver).literal("f20ü", "Deutsche Binnenwasserstraßen");
                    ordered.verify(receiver).literal("f20_", "Deutsche Binnenwasserstraßen : Nachgewiesen 2008 -");
                    ordered.verify(receiver).literal("f01_", "Nachgewiesen 2008 -");
                    ordered.verify(receiver).endRecord();
                    ordered.verifyNoMoreInteractions();
                });
    }

    @Test
    public void processPeriodicalWithMultipleVolumes() {
       // 'sm' & 'sbd' in '#36 ' & '#88 ' -> treat as Periodical with their own titles
        test("[/]#00 929t111930[/]#20 Sommerspiele Koblenz : Operette auf dem Rhein[/]#36 sm[/]#88 1201241-5[/]"
                + "#01 1958 - 1968 nachgewiesen[/]#36 sbd[/]",
                () -> {
                    final InOrder ordered = inOrder(receiver);
                    ordered.verify(receiver).startRecord("929t111930");
                    ordered.verify(receiver).literal("f00_", "929t111930");
                    ordered.verify(receiver).literal("f20_", "Sommerspiele Koblenz : Operette auf dem Rhein");
                    ordered.verify(receiver).literal("f36_", "sm");
                    ordered.verify(receiver).literal("f88_", "1201241-5");
                    ordered.verify(receiver).literal("f36t", "Periodical");
                    ordered.verify(receiver).endRecord();
                    ordered.verify(receiver).startRecord("929t111930b1");
                    ordered.verify(receiver).literal("f00_", "929t111930b1");
                    ordered.verify(receiver).literal("f20ü", "Sommerspiele Koblenz : Operette auf dem Rhein");
                    ordered.verify(receiver).literal("f20_", "Sommerspiele Koblenz : Operette auf dem Rhein : 1958 - 1968 nachgewiesen");
                    ordered.verify(receiver).literal("f01_", "1958 - 1968 nachgewiesen");
                    ordered.verify(receiver).literal("f36_", "sbd");
                    ordered.verify(receiver).endRecord();
                    ordered.verifyNoMoreInteractions();
                });
    }

    @Test
    public void processRecordWithMultipleTitles() {
        // No 'sm' in '#36 ' -> treat as multiple titles of single volume
        test("[/]#00 929t124030[/]#20 Deutsche Binnenwasserstraßen[/]#36 TEST[/]"
                + "#01 6[/]#20 Der Rhein - Rheinfelden bis Koblenz[/]"
                + "#01 7[/]#20 Der Rhein - Koblenz bis Tolkamer[/]", () -> {
                    final InOrder ordered = inOrder(receiver);
                    ordered.verify(receiver).startRecord("929t124030");
                    ordered.verify(receiver).literal("f00_", "929t124030");
                    ordered.verify(receiver).literal("f20_", "Deutsche Binnenwasserstraßen");
                    ordered.verify(receiver).literal("f36_", "TEST");
                    ordered.verify(receiver).literal("f01_", "6");
                    ordered.verify(receiver).literal("f20_", "Der Rhein - Rheinfelden bis Koblenz");
                    ordered.verify(receiver).literal("f01_", "7");
                    ordered.verify(receiver).literal("f20_", "Der Rhein - Koblenz bis Tolkamer");
                    ordered.verify(receiver).endRecord();
                    ordered.verifyNoMoreInteractions();
                });
    }

    @Test
    public void processError() {
        exception.expect(MetafactureException.class);
        exception.expectMessage(startsWith("Can't get ID from input"));
        decode.process("[/]#01something[/]");
    }

    private void test(final String in, final Runnable r) throws MockitoAssertionError {
        try {
            decode.process(in);
            r.run();
            Mockito.verifyNoMoreInteractions(receiver);
        }
        catch (final MockitoAssertionError e) {
            System.out.println("\nDecoding string: " + in);
            System.out.println(Mockito.mockingDetails(receiver).printInvocations());
            throw e;
        }
    }
}

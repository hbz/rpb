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
            ordered.verify(receiver).literal("#00 ", "123");
            ordered.verify(receiver).literal("#20 ", "abc");
            ordered.verify(receiver).literal("#983", "HT011020818");
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
package rpb;

import java.util.Arrays;
import java.util.Collection;

import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.metafacture.metafix.Record;
import org.metafacture.metafix.Value;

@RunWith(Parameterized.class)
public final class StripDiacriticsTest {

    private static final Object[][] PARAMS = new Object[][] {
            { "Siée", /* -> */ "Siee" }, { "Chajjâm", /* -> */ "Chajjam" },
            { "Haën", /* -> */ "Haen" }, { "Köln", /* -> */ "Köln" } };

    @Parameterized.Parameters(name = "{0} -> {1}")
    public static Collection<Object[]> testCases() {
        return Arrays.asList(PARAMS);
    }

    private String in;
    private String out;

    public StripDiacriticsTest(String in, String out) {
        this.in = in;
        this.out = out;
    }

    @Test
    public void HtmlToText() {
        Record record = new Record();
        record.add("test", new Value(in));
        new StripDiacritics().apply(null, record, Arrays.asList("test"), null);
        Assert.assertEquals(out, record.get("test").asString());
    }
}

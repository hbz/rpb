package rpb;

import java.text.Normalizer;
import java.util.List;
import java.util.Map;

import org.metafacture.metafix.Metafix;
import org.metafacture.metafix.Record;
import org.metafacture.metafix.api.FixFunction;

public class StripDiacritics implements FixFunction {

    @Override
    public void apply(final Metafix metafix, final Record record, final List<String> params,
            final Map<String, String> options) {
        record.transform(params.get(0), s -> s.toLowerCase().matches(".*[äöü].*") ? s
                : Normalizer.normalize(s, Normalizer.Form.NFKD).replaceAll("[\\p{InCombiningDiacriticalMarks}]", ""));
    }

}

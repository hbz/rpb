package rpb;

import org.apache.log4j.Logger;
import org.metafacture.framework.StreamReceiver;
import org.metafacture.framework.helpers.DefaultObjectPipe;

/**
 * Decode RPB Allegro export data.
 */
public final class Decode extends DefaultObjectPipe<String, StreamReceiver> {
    
    private static final Logger LOG = Logger.getLogger(Decode.class);

    @Override
    public void process(final String obj) {
        final String[] vals = obj.replace("[/]", "\uFFFF").split("\uFFFF");
        final String[] idKeyVal = vals[1].trim().split(" ");
        LOG.info("Process record: " + idKeyVal[1]);
        getReceiver().startRecord(idKeyVal[1]);
        getReceiver().literal(idKeyVal[0], idKeyVal[1]);
        processFields(vals);
        getReceiver().endRecord();
    }

    private void processFields(final String[] vals) {
        for (int i = 2; i < vals.length; i++) {
            final String[] keyVal = vals[i].trim().split("(?<=#\\d{2}).*?");
            if (keyVal.length == 2) {
                getReceiver().literal(keyVal[0], keyVal[1]);
            }
        }
    }
}

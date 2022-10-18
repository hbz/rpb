/* Copyright 2022 Fabian Steeg, hbz. Licensed under the GPLv2 */

package rpb;

import org.apache.log4j.Logger;
import org.metafacture.framework.MetafactureException;
import org.metafacture.framework.StreamReceiver;
import org.metafacture.framework.helpers.DefaultObjectPipe;

/**
 * Decode RPB Allegro export data.
 */
public final class Decode extends DefaultObjectPipe<String, StreamReceiver> {

    private static final int FIELD_NAME_SIZE = 4; // e.g. '#983'
    private static final Logger LOG = Logger.getLogger(Decode.class);
    private String recordId;
    private String recordTitle;
    private boolean inMultiVolumeRecord;

    @Override
    public void process(final String obj) {
        LOG.debug("Process record: " + obj);
        final String[] vals = obj.split("\\[/\\]");
        recordId = getId(obj, vals);
        getReceiver().startRecord(recordId);
        processFields(vals);
        getReceiver().endRecord();
        inMultiVolumeRecord = false;
    }

    private String getId(final String obj, final String[] vals) {
        if (vals.length < 2 || !vals[1].trim().startsWith("#00 ")) {
            throw new MetafactureException("Can't get ID from input: " + obj);
        }
        return vals[1].trim().substring(FIELD_NAME_SIZE);
    }

    private void processFields(final String[] vals) {
        boolean firstVolume = true;
        for (int i = 1; i < vals.length; i++) {
            final String k = vals[i].substring(0, FIELD_NAME_SIZE);
            final String v = vals[i].substring(FIELD_NAME_SIZE);
            if("#20 ".equals(k) && !inMultiVolumeRecord) {
                recordTitle = v;
            }
            if("#36 ".equals(k) && "sm".equals(v)) {
                inMultiVolumeRecord = true;
            } else if(inMultiVolumeRecord && "#01 ".equals(k)) {
                if(firstVolume) {
                    // we're still in the main (multi volume) record, so we mark that here:
                    getReceiver().literal("#36t", "MultiVolumeBook");
                    firstVolume = false;
                }
                getReceiver().endRecord(); // first time, we end main record, then each volume
                final String fullRecordId = recordId + "-" + v.replaceAll("\\D", "");
                getReceiver().startRecord(fullRecordId);
                getReceiver().literal("#00 ", fullRecordId);
                getReceiver().literal("#20ü", recordTitle);
            }
            getReceiver().literal(k, v);
        }
    }

}

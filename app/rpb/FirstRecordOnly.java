/* Copyright 2025 Fabian Steeg, hbz. Licensed under the GPLv2 */

package rpb;

import java.util.HashSet;

import org.metafacture.framework.MetafactureException;
import org.metafacture.framework.ObjectReceiver;
import org.metafacture.framework.helpers.DefaultObjectPipe;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Pass only first occurence of a JSON record (identified by its `data.id`)
 */
public final class FirstRecordOnly extends DefaultObjectPipe<String, ObjectReceiver<String>> {

    private static final ObjectMapper MAPPER = new ObjectMapper();
    private HashSet<String> ids = new HashSet<>();

    @Override
    public void process(final String obj) {
        try {
            JsonNode data = MAPPER.readTree(obj).get("data");
            if (data != null) {
                JsonNode idNode = data.get("id");
                String id;
                if (idNode != null && !ids.contains(id = idNode.asText())) {
                    getReceiver().process(obj);
                    ids.add(id);
                }
            }
        } catch (JsonProcessingException e) {
            throw new MetafactureException(e);
        }
    }

}

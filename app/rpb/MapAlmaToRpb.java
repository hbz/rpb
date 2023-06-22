/* Copyright 2023 Fabian Steeg, hbz. Licensed under the GPLv2 */

package rpb;

import java.io.IOException;
import java.net.URL;
import java.net.URLConnection;

import org.metafacture.framework.ObjectReceiver;
import org.metafacture.framework.helpers.DefaultStreamPipe;

import com.fasterxml.jackson.databind.JsonNode;

import play.Logger;
import play.libs.Json;

/**
 * Create a mapping for RPB Allegro export data with hbzIds: map almaMmsId to rpbId.
 */
public final class MapAlmaToRpb extends DefaultStreamPipe<ObjectReceiver<String>> {

    private String id;
    @Override
    public void startRecord(String identifier) {
        this.id = identifier;
        super.startRecord(identifier);
    }
    @Override
    public void literal(String name, String hbzId) {
        String almaMmsId = getAlmaMmsId(hbzId);
        getReceiver().process(String.format("%s\tRPB%s", almaMmsId, id));
    }
    private String getAlmaMmsId(String hbzId) {
        String url = "https://test.lobid.org/resources/" + hbzId;
        Logger.debug("Trying to get almaMmsId from: " + url);
        try {
            URLConnection connection = new URL(url).openConnection();
            connection.setRequestProperty("Accept", "application/json");
            connection.connect();
            JsonNode jsonNode = Json.parse(connection.getInputStream());
            Thread.sleep(100);
            return jsonNode.get("almaMmsId").textValue();
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
        return "#983: " + hbzId;
    }

}

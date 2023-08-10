/* Copyright 2023 Fabian Steeg, hbz. Licensed under the GPLv2 */

package rpb;

import org.apache.log4j.Logger;
import org.metafacture.framework.MetafactureException;
import org.metafacture.framework.ObjectReceiver;
import org.metafacture.framework.helpers.DefaultObjectPipe;

/**
 * Wait for a specified time.
 */
public final class Wait extends DefaultObjectPipe<String, ObjectReceiver<String>> {

	private long time = 200;
	private static final Logger LOG = Logger.getLogger(Wait.class);

	@Override
	public void process(String obj) {
		LOG.info(""); // HTTP response / error w/o newline
		LOG.info("Waiting for " + time + " ms.");
		try {
			Thread.sleep(time);
		} catch (InterruptedException e) {
			throw new MetafactureException("Exception while waiting", e);
		}
		getReceiver().process(obj);
	}

}

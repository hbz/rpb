package tests;

import org.junit.runner.RunWith;
import org.junit.runners.Suite;
import org.junit.runners.Suite.SuiteClasses;

import rpb.DecodeTest;
import rpb.EtlTest;

/**
 * All quick, self-contained tests for running as CI. For running all
 * tests, including long running tests and integration tests with dependencies
 * on external services see {@link AllTests}.
 * 
 * @author Fabian Steeg (fsteeg)
 *
 */
@RunWith(Suite.class)
@SuiteClasses({ ApplicationTest.class, InternalIntegrationTest.class, DecodeTest.class, EtlTest.class })
public class CITests {
	//
}

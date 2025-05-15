/* Copyright 2014 Fabian Steeg, hbz. Licensed under the GPLv2 */

package tests;

import static org.fest.assertions.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static play.test.Helpers.GET;
import static play.test.Helpers.fakeRequest;
import static play.test.Helpers.route;
import static play.test.Helpers.running;
import static play.test.Helpers.testServer;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.apache.commons.lang3.tuple.Pair;
import org.junit.Before;
import org.junit.Test;

import com.fasterxml.jackson.databind.JsonNode;

import controllers.rpb.Application;
import controllers.rpb.Classification;
import controllers.rpb.Lobid;
import controllers.rpb.Classification.Type;
import play.libs.F.Promise;
import play.libs.Json;
import play.mvc.Http;
import play.mvc.Result;
import play.test.Helpers;
import play.twirl.api.Content;

/**
 * See http://www.playframework.com/documentation/2.3.x/JavaFunctionalTest
 */
public class InternalIntegrationTest {

	@Before
	public void setUp() throws Exception {
		Map<String, String> flashData = Collections.emptyMap();
		Map<String, Object> argData = Collections.emptyMap();
		play.api.mvc.RequestHeader header = mock(play.api.mvc.RequestHeader.class);
		Http.Request request = mock(Http.Request.class);
		Http.Context context =
				new Http.Context(2L, header, request, flashData, flashData, argData);
		Http.Context.current.set(context);
	}

	@Test
	public void testFacets() {
		running(testServer(3333), () -> {
			String field = Application.TYPE_FIELD;
			Promise<JsonNode> jsonPromise = Lobid.getFacets("*", "", "", "", "",
					"", "", "", "", "", "", field, "", "", "", "", "");
			JsonNode facets = jsonPromise.get(Lobid.API_TIMEOUT);
			assertThat(facets.findValue("aggregation").findValues("key").stream()
					.map(e -> e.asText()).collect(Collectors.toList())).contains(
							"BibliographicResource", "Article", "Book", "MultiVolumeBook", "Map", "Festschrift",
							"Biography", "Miscellaneous", "Periodical", "Proceedings", "EditedVolume",
							"PublicationIssue");
			assertThat(facets.findValues("count").stream().map(e -> e.intValue())
					.collect(Collectors.toList())).excludes(0);
		});
	}

	@Test
	public void spatialClassificationLabel() {
		running(testServer(3333), () -> {
			assertThat(
					Classification.label("https://rpb.lobid.org/spatial#n1", Type.SPATIAL))
							.as("rpb spatial label").isEqualTo("Rheinland-Pfalz insgesamt. Landesteile");
		});
	}

	@Test
	public void testSubjectLabelAndRpbQuery() {
		running(testServer(3333), () -> {
			assertThat(hitsFor("subject=cochem")).as("less-filtered result count")
					.isGreaterThan(
							hitsFor("subject=cochem&rpbsubject=" + rpb("n102070")));
		});
	}

	@Test
	public void testSubjectUriAndRpbQuery() {
		running(testServer(3333), () -> {
			assertThat(hitsFor("subject=" + gnd("4001307-8")))
					.as("less-filtered result count").isGreaterThan(hitsFor("subject="
							+ gnd("4001307-8") + "&rpbsubject=" + rpb("n882060")));
		});
	}

	@Test
	public void testLeadingBlanksInSearchQ() {
		searchLeadingBlankWith("q=");
	}

	@Test
	public void testLeadingBlanksInSearchWord() {
		searchLeadingBlankWith("word=");
	}

	private static void searchLeadingBlankWith(String param) {
		running(testServer(3333), () -> {
			try {
				assertThat(hitsFor(param + URLEncoder.encode(
						" Die Kölner Wurzeln der Cochemer Apothekerfamilie Pliester",
						StandardCharsets.UTF_8.name()))).as("less-filtered result count")
								.isGreaterThan(0);
			} catch (UnsupportedEncodingException e) {
				e.printStackTrace();
			}
		});
	}

	private static String rpb(String string) {
		return "http%3A%2F%2Fpurl.org%2Flobid%2Frpb%23" + string;
	}

	private static String gnd(String string) {
		return "https%3A%2F%2Fd-nb.info%2Fgnd%2F" + string;
	}

	private static Long hitsFor(String params) {
		Result result = route(fakeRequest(GET, "/search?format=json&" + params));
		assertThat(result).isNotNull();
		return Json.parse(Helpers.contentAsString(result)).get("totalItems")
				.asLong();
	}

	@Test
	public void renderTemplate() {
		String query = "buch";
		int from = 0;
		int size = 10;
		running(testServer(3333), () -> {
			Content html = views.html.search.render("[{}]", query, "", "", "", "", "",
					"", "", "", "", from, size, 0L, "", "", "", "", "", "", "");
			assertThat(html.contentType()).isEqualTo("text/html");
			String text = Helpers.contentAsString(html);
			assertThat(text).contains("RPB").contains("buch");
		});
	}

	@Test
	public void sizeRequest() {
		running(testServer(3333), () -> {
			Long hits = Lobid
					.getTotalHits("isPartOf.hasSuperordinate.id",
							"http://lobid.org/resources/HT030703238#!", "")
					.get(Lobid.API_TIMEOUT);
			assertThat(hits).as("1").isGreaterThan(0);
			hits = Lobid
					.getTotalHits("containedIn.id",
							"http://lobid.org/resources/990054367970206441#!", "")
					.get(Lobid.API_TIMEOUT);
			assertThat(hits).as("2").isGreaterThan(0);
		});
	}

	@Test
	public void sizeRequestClassifications() {
		running(testServer(3333), () -> {
			Long hits = Lobid.getTotalHitsRpbClassification("https://rpb.lobid.org/spatial#n05");
			assertThat(hits).as("hits for spatial#n05").isGreaterThan(0);
			hits = Lobid.getTotalHitsRpbClassification("http://purl.org/lobid/rpb#n102060");
			assertThat(hits).as("hits for rpb#n102060").isGreaterThan(0);
		});
	}

	@Test
	public void pathToClassificationId_leaf() {
		running(testServer(3333), () -> {
			assertThat(Classification.pathTo("http://purl.org/lobid/rpb#n865052"))
					.as("path in classification")
					.isEqualTo(Arrays.asList(//
							"http://purl.org/lobid/rpb#n860000",
							"http://purl.org/lobid/rpb#n865000",
							"http://purl.org/lobid/rpb#n865050",
							"http://purl.org/lobid/rpb#n865052"));
		});
	}

	@Test
	public void pathToClassificationId_inner() {
		running(testServer(3333), () -> {
			assertThat(Classification.pathTo("http://purl.org/lobid/rpb#n865050"))
					.as("path in classification")
					.isEqualTo(Arrays.asList(//
							"http://purl.org/lobid/rpb#n860000",
							"http://purl.org/lobid/rpb#n865000",
							"http://purl.org/lobid/rpb#n865050"));
		});
	}

	@Test
	public void pathToClassificationId_last() {
		running(testServer(3333), () -> {
			assertThat(Classification.pathTo("http://purl.org/lobid/rpb#n865090"))
					.as("path in classification")
					.isEqualTo(Arrays.asList(//
							"http://purl.org/lobid/rpb#n860000",
							"http://purl.org/lobid/rpb#n865000",
							"http://purl.org/lobid/rpb#n865090"));
		});
	}

	@Test
	public void pathToSpatialClassificationId() {
		running(testServer(3333), () -> {
			assertThat(Classification.pathTo("https://rpb.lobid.org/spatial#n135010200102"))
					.as("path in spatial classification").isEqualTo(Arrays.asList(//
							"https://rpb.lobid.org/spatial#n6",
							"https://rpb.lobid.org/spatial#n135",
							"https://rpb.lobid.org/spatial#n13501",
							"https://rpb.lobid.org/spatial#n13501020",
							"https://rpb.lobid.org/spatial#n135010200102"));
		});
	}

	@Test
	public void pathToSpatialClassificationGndId() {
		running(testServer(3333), () -> {
			assertThat(Classification.pathTo("https://rpb.lobid.org/spatial#n4288874n8"))
					.as("path in spatial classification")
					.isEqualTo(Arrays.asList(//
							"https://rpb.lobid.org/spatial#n4",
							"https://rpb.lobid.org/spatial#n50",
							"https://rpb.lobid.org/spatial#n4288874n8"));
		});
	}

	@Test
	public void pathToSpatialClassificationId_notFound() {
		running(testServer(3333), () -> {
			assertThat(Classification.pathTo("http://www.example.org"))
					.as("path in spatial classification")
					.isEqualTo(Arrays.asList("http://www.example.org"));
		});
	}

	@Test
	public void buildSpatialHierarchy() {
		running(testServer(3333), () -> {
			Pair<List<JsonNode>, Map<String, List<JsonNode>>> pair =
					Classification.Type.SPATIAL.buildHierarchy();
			assertThat(pair.getLeft().size()).isEqualTo(6);
			assertThat(pair.getRight().get("https://rpb.lobid.org/spatial#n5").size())
					.isGreaterThan(0);
			assertThat(pair.getRight().get("https://rpb.lobid.org/spatial#n6").size())
					.isGreaterThan(0);
		});
	}

	@Test
	public void classificationSubjectRegister() {
		running(testServer(3333), () -> {
			JsonNode register =
					Classification.Type.from("Sachsystematik").buildRegister();
			assertThat(register.toString()).contains("Audiovisuelle Medien")
					.contains("Publizistik").contains("Bibliotheksrecht")
					.contains("Schulbibliothek");
		});
	}

}

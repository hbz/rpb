/* Copyright 2014 Fabian Steeg, hbz. Licensed under the GPLv2 */

package tests;

import static controllers.rpb.Application.CONFIG;
import static org.fest.assertions.Assertions.assertThat;

import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Arrays;
import java.util.List;

import org.junit.Assert;
import org.junit.Test;

import com.fasterxml.jackson.databind.JsonNode;

import controllers.rpb.Application;
import controllers.rpb.Classification;
import controllers.rpb.Classification.Type;
import controllers.rpb.Lobid;

import play.libs.Json;

/**
 * See http://www.playframework.com/documentation/2.3.x/JavaTest
 */
public class ApplicationTest {

	@Test
	public void shortClassificationId() {
		assertThat(Classification.shortId("http://purl.org/lobid/rpb#n141020"))
				.as("short classification").isEqualTo("141020");
	}

	@Test
	public void shortSpatialClassificationId() {
		assertThat(Classification.shortId("https://rpb.lobid.org/spatial#n131015010200"))
				.as("short spatial classification").isEqualTo("131015010200");
	}

	@Test
	public void classificationLabelNotAvailable() {
		assertThat(
				Classification.label("https://rpb.lobid.org/spatial#n9", Type.SPATIAL))
						.as("empty label").isEqualTo("");
	}

	@Test
	public void typeSelectionMultiVolumeBook() {
		String selected = Lobid.selectType(
				Arrays.asList("BibliographicResource", "MultiVolumeBook", "Book"),
				"type.labels");
		assertThat(selected).isEqualTo("MultiVolumeBook");
	}

	@Test
	public void typeSelectionPublishedScore() {
		String selected = Lobid.selectType(
				Arrays.asList("MultiVolumeBook", "PublishedScore", "Book"),
				"type.labels");
		assertThat(selected).isEqualTo("PublishedScore");
	}

	@Test
	public void typeSelectionEditedVolume() {
		String selected = Lobid.selectType(Arrays.asList("MultiVolumeBook",
				"BibliographicResource", "EditedVolume"), "type.labels	");
		assertThat(selected).isEqualTo("EditedVolume");
	}

	@Test
	public void classificationrpbsubject()
			throws MalformedURLException, IOException {
		List<String> rpbsubjects = Classification
				.toJsonLd(new URL(CONFIG.getString("index.data.rpbsubject")));
		rpbsubjects.forEach(System.out::println);
		assertThat(rpbsubjects.size()).isGreaterThan(1000);
		assertThat(rpbsubjects.toString()).contains("Landeskunde allgemein")
				.contains("Landesbeschreibung").contains("Hydroökologie");
	}

	@Test
	public void classificationrpbspatial()
			throws MalformedURLException, IOException {
		List<String> rpbspatials = Classification
				.toJsonLd(new URL(CONFIG.getString("index.data.rpbspatial")));
		rpbspatials.forEach(System.out::println);
		assertThat(rpbspatials.size()).isGreaterThan(5);
		assertThat(rpbspatials.toString()).contains("Rheinland-Pfalz")
				.contains("Landschaften").contains("Verbandsgemeinden");
	}

	@Test
	public void sortArabicNumerals() {
		JsonNode[] in = new JsonNode[] { //
				Json.newObject().put("label", "Stadtbezirk 10"),
				Json.newObject().put("label", "Stadtbezirk 9"),
				Json.newObject().put("label", "Stadtbezirk 8"),
				Json.newObject().put("label", "Stadtbezirk 7"),
				Json.newObject().put("label", "Stadtbezirk 6"),
				Json.newObject().put("label", "Stadtbezirk 5"),
				Json.newObject().put("label", "Stadtbezirk 4"),
				Json.newObject().put("label", "Stadtbezirk 3"),
				Json.newObject().put("label", "Stadtbezirk 2"),
				Json.newObject().put("label", "Stadtbezirk 1") };
		JsonNode[] correct = new JsonNode[] { //
				Json.newObject().put("label", "Stadtbezirk 1"),
				Json.newObject().put("label", "Stadtbezirk 2"),
				Json.newObject().put("label", "Stadtbezirk 3"),
				Json.newObject().put("label", "Stadtbezirk 4"),
				Json.newObject().put("label", "Stadtbezirk 5"),
				Json.newObject().put("label", "Stadtbezirk 6"),
				Json.newObject().put("label", "Stadtbezirk 7"),
				Json.newObject().put("label", "Stadtbezirk 8"),
				Json.newObject().put("label", "Stadtbezirk 9"),
				Json.newObject().put("label", "Stadtbezirk 10") };
		Arrays.sort(in, Classification.comparator(Classification::labelText));
		Assert.assertArrayEquals(correct, in);
	}

	@Test
	public void sortRomanNumerals() {
		JsonNode[] in = new JsonNode[] { //
				Json.newObject().put("label", "Stadtbezirk X"),
				Json.newObject().put("label", "Stadtbezirk IX"),
				Json.newObject().put("label", "Stadtbezirk VIII"),
				Json.newObject().put("label", "Stadtbezirk VII"),
				Json.newObject().put("label", "Stadtbezirk VI"),
				Json.newObject().put("label", "Stadtbezirk V"),
				Json.newObject().put("label", "Stadtbezirk IV"),
				Json.newObject().put("label", "Stadtbezirk III"),
				Json.newObject().put("label", "Stadtbezirk II"),
				Json.newObject().put("label", "Stadtbezirk I") };
		JsonNode[] correct = new JsonNode[] { //
				Json.newObject().put("label", "Stadtbezirk I"),
				Json.newObject().put("label", "Stadtbezirk II"),
				Json.newObject().put("label", "Stadtbezirk III"),
				Json.newObject().put("label", "Stadtbezirk IV"),
				Json.newObject().put("label", "Stadtbezirk V"),
				Json.newObject().put("label", "Stadtbezirk VI"),
				Json.newObject().put("label", "Stadtbezirk VII"),
				Json.newObject().put("label", "Stadtbezirk VIII"),
				Json.newObject().put("label", "Stadtbezirk IX"),
				Json.newObject().put("label", "Stadtbezirk X") };
		Arrays.sort(in, Classification.comparator(Classification::labelText));
		Assert.assertArrayEquals(correct, in);
	}

	@Test
	public void removeNonFormattingControlCharacters() {
		assertThat(Application
				.removeNonFormattingControlCharacters("\u0098Der\u009c Gau-Algesheimer Weihnachtsmarkt"))
				.as("Non-formatting control characters should be removed")
				.doesNotContain("\u0098")
				.doesNotContain("\u009c");
		assertThat(Application
				.removeNonFormattingControlCharacters("Line1\r\nLine2\n\tIndented"))
				.as("Tabs and newlines should be retained")
				.contains("\r")
				.contains("\n")
				.contains("\t");
	}

}

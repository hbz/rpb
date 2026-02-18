/* Copyright 2019, 2026 Fabian Steeg, hbz. Licensed under the GPLv2 */

import static play.test.Helpers.running;
import static play.test.Helpers.testServer;

import java.io.FileWriter;
import java.io.IOException;
import java.io.StringWriter;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

import org.apache.commons.lang3.tuple.Pair;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.riot.Lang;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.SKOS;

import com.fasterxml.jackson.databind.JsonNode;

import controllers.rpb.Classification;
import controllers.rpb.Lobid;

/**
 * Generate a SKOS representation from the internal rpb classification data
 * (which itself originates from a SKOS file)
 * 
 * @author Fabian Steeg (fsteeg)
 *
 */
public class RpbToSkos {

	private static final String RPB_CLASSIFICATION = "http://purl.org/lobid/rpb";
	private static final String RPB_CLASSIFICATION_NAMESPACE = RPB_CLASSIFICATION + "#";

	/**
	 * Write a SKOS turtle file for rpb classification to the conf/ folder
	 * 
	 * @param args
	 *             Not used
	 */
	public static void main(String[] args) {
		AtomicInteger exitCode = new AtomicInteger(-1);
		running(testServer(3333), () -> {
			Model model = ModelFactory.createDefaultModel();
			setUpNamespaces(model);
			Pair<List<JsonNode>, Map<String, List<JsonNode>>> topAndSub = Classification.Type.from("Sachsystematik")
					.buildHierarchy();
			Resource scheme = addConceptScheme(model);
			addTopLevelConcepts(model, topAndSub.getLeft(), scheme);
			addHierarchy(model, topAndSub.getRight());
			write(model);
		});
		System.exit(exitCode.get());
	}

	private static void setUpNamespaces(Model model) {
		model.setNsPrefix("", RPB_CLASSIFICATION_NAMESPACE);
		model.setNsPrefix("rdf", "http://www.w3.org/1999/02/22-rdf-syntax-ns#");
		model.setNsPrefix("dct", DCTerms.NAMESPACE.toString());
		model.setNsPrefix("skos", SKOS.NAMESPACE.toString());
		model.setNsPrefix("vann", "http://purl.org/vocab/vann/");
	}

	private static Resource addConceptScheme(Model model) {
		return model.createResource(RPB_CLASSIFICATION, SKOS.ConceptScheme)//
				.addProperty(DCTerms.title, "Systematik der Rheinland-Pfälzischen Bibliographie", "de")
				.addProperty(DCTerms.title, "Classification scheme for the bibliography of Rhineland-Palatinate",
						"en")
				.addProperty(DCTerms.license, model.createResource("http://creativecommons.org/publicdomain/zero/1.0/"))
				.addProperty(DCTerms.description,
						"This classification was created for use in the bibliography of Rhineland-Palatinate (RPB). The transformation to SKOS was carried out by Felix Ostrowski for the hbz.",
						"en")
				.addProperty(DCTerms.issued, "2014-01-28")
				.addProperty(DCTerms.modified, ZonedDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE))
				.addProperty(DCTerms.publisher, model.createResource("http://lobid.org/organisations/DE-605"))
				.addProperty(model.createProperty("http://purl.org/vocab/vann/preferredNamespaceUri"),
						RPB_CLASSIFICATION_NAMESPACE)
				.addProperty(model.createProperty("http://purl.org/vocab/vann/preferredNamespacePrefix"),
						"rpb-spatial");
	}

	private static void addTopLevelConcepts(Model model, List<JsonNode> topLevel, Resource scheme) {
		topLevel.forEach(top -> {
			Resource resource = addInSchemeAndPrefLabel(model, top);
			resource.addProperty(SKOS.notation, top.get("notation").asText());
			scheme.addProperty(SKOS.hasTopConcept, model.createResource(top.get("value").asText()));
		});
	}

	private static void addHierarchy(Model model, Map<String, List<JsonNode>> hierarchy) {
		hierarchy.entrySet().forEach(sub -> {
			sub.getValue().forEach(entry -> {
				try {
					String superSubject = sub.getKey();
					Resource resource = addInSchemeAndPrefLabel(model, entry);
					resource.addProperty(SKOS.broader, model.createResource(superSubject));
					resource.addProperty(SKOS.notation, entry.get("notation").asText());
					resource.addProperty(SKOS.definition,
							Classification
									.pathTo(entry.get("value").asText()).stream().map(uri -> String.format("%s (n%s)",
											Lobid.facetLabel(Arrays.asList(uri), "", ""), Classification.shortId(uri)))
									.collect(Collectors.joining(" > ")),
							"de");
				} catch (Exception e) {
					System.err.println("Error processing: " + entry);
					e.printStackTrace();
				}
			});
		});
	}

	private static Resource addInSchemeAndPrefLabel(Model model, JsonNode top) {
		String subject = top.get("value").asText();
		String label = top.get("label").asText().replaceAll("<span class='notation'>([^<]*)</span>", "").trim();
		Resource result = model.createResource(subject, SKOS.Concept)//
				.addProperty(SKOS.inScheme, model.createResource(RPB_CLASSIFICATION))
				.addProperty(SKOS.prefLabel, label, "de");
		return result;
	}

	private static void write(Model model) {
		String outputFile = "conf/rpb.ttl";
		try (FileWriter fw = new FileWriter(outputFile)) {
			fw.write(toSortedTurtle(model));
			System.out.println("Wrote TTL output to: " + outputFile);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private static String toSortedTurtle(Model model) throws IOException {
		StringWriter stringWriter = new StringWriter();
		model.write(stringWriter, Lang.TURTLE.getName());
		String blankLine = "\n\n";
		String[] sections = stringWriter.toString().split(blankLine);
		Arrays.sort(sections);
		StringBuilder result = new StringBuilder();
		result.append(sections[sections.length - 1].trim()).append(blankLine);
		result.append(sections[sections.length - 2].trim()).append(blankLine);
		for (int i = 0; i < sections.length - 2; i++) {
			result.append(sections[i].trim()).append(blankLine);
		}
		return result.toString();
	}
}

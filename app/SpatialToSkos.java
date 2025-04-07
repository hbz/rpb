
/* Copyright 2019, 2022 Fabian Steeg, hbz. Licensed under the GPLv2 */

import static play.test.Helpers.running;
import static play.test.Helpers.testServer;

import java.io.FileWriter;
import java.io.IOException;
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
import org.apache.jena.sparql.vocabulary.FOAF;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.SKOS;

import com.fasterxml.jackson.databind.JsonNode;

import controllers.nwbib.Classification;
import controllers.nwbib.Lobid;

/**
 * Generate a SKOS representation from the internal spatial classification data
 * (which itself originates from a SKOS file, but is enriched from different
 * sources, see https://jira.hbz-nrw.de/browse/RPB-21)
 * 
 * @author Fabian Steeg (fsteeg)
 *
 */
public class SpatialToSkos {

	private static final String RPB_SPATIAL = "https://rpb.lobid.org/spatial";
	private static final String RPB_SPATIAL_NAMESPACE = RPB_SPATIAL + "#";

	/**
	 * Write a SKOS turtle file for rpb-spatial to the conf/ folder
	 * 
	 * @param args
	 *            Not used
	 */
	public static void main(String[] args) {
		AtomicInteger exitCode = new AtomicInteger(-1);
		running(testServer(3333), () -> {
			Model model = ModelFactory.createDefaultModel();
			setUpNamespaces(model);
			Pair<List<JsonNode>, Map<String, List<JsonNode>>> topAndSub = Classification.Type.from("Raumsystematik")
					.buildHierarchy();
			Resource scheme = addConceptScheme(model);
			addTopLevelConcepts(model, topAndSub.getLeft(), scheme);
			addHierarchy(model, topAndSub.getRight());
			write(model);
		});
		System.exit(exitCode.get());
	}

	private static void setUpNamespaces(Model model) {
		model.setNsPrefix("skos", SKOS.NAMESPACE.toString());
		model.setNsPrefix("foaf", FOAF.NAMESPACE.toString());
		model.setNsPrefix("dct", DCTerms.NAMESPACE.toString());
		model.setNsPrefix("vann", "http://purl.org/vocab/vann/");
		model.setNsPrefix("", RPB_SPATIAL_NAMESPACE);
		model.setNsPrefix("wd", "http://www.wikidata.org/entity/");
	}

	private static Resource addConceptScheme(Model model) {
		return model.createResource(RPB_SPATIAL, SKOS.ConceptScheme)//
				.addProperty(DCTerms.title, "Raumsystematik der Rheinland-Pfälzischen Bibliographie", "de")
				.addProperty(DCTerms.title, "Spatial classification scheme for the Bibiography of Rhineland-Palatinate",
						"en")
				.addProperty(DCTerms.license, model.createResource("http://creativecommons.org/publicdomain/zero/1.0/"))
				.addProperty(DCTerms.description,
						"This controlled vocabulary for areas in Rineland-Palatinate was created for use in the Bibliography of Rhineland (RPB).", "en")
				.addProperty(DCTerms.issued, "2022-08-26")
				.addProperty(DCTerms.modified, ZonedDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE))
				.addProperty(DCTerms.publisher, model.createResource("http://lobid.org/organisations/DE-605"))
				.addProperty(model.createProperty("http://purl.org/vocab/vann/preferredNamespaceUri"),
						RPB_SPATIAL_NAMESPACE)
				.addProperty(model.createProperty("http://purl.org/vocab/vann/preferredNamespacePrefix"),
						"rpb-spatial");
	}

	private static void addTopLevelConcepts(Model model, List<JsonNode> topLevel, Resource scheme) {
		topLevel.forEach(top -> {
			addInSchemeAndPrefLabel(model, top);
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
					resource.addProperty(SKOS.definition,
							Classification
									.pathTo(entry.get("value").asText()).stream().map(uri -> String.format("%s (n%s)",
											Lobid.facetLabel(Arrays.asList(uri), "", ""), Classification.shortId(uri)))
									.collect(Collectors.joining(" > ")), "de");
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
				.addProperty(SKOS.inScheme, model.createResource(RPB_SPATIAL))
				.addProperty(SKOS.prefLabel, label, "de");
		return result;
	}

	private static void write(Model model) {
		model.write(System.out, Lang.TURTLE.getName());
		try (FileWriter fw = new FileWriter("conf/rpb-spatial.ttl")) {
			model.write(fw, Lang.TURTLE.getName());
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

}

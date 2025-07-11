/* Copyright 2014-2015 Fabian Steeg, hbz. Licensed under the GPLv2 */

package views;

import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import com.fasterxml.jackson.databind.JsonNode;
import com.google.common.html.HtmlEscapers;

import controllers.rpb.Application;
import static controllers.rpb.Application.CONFIG;
import controllers.rpb.Classification;
import controllers.rpb.Lobid;
import play.Logger;
import play.libs.ws.WS;
import play.libs.ws.WSRequest;
import play.libs.ws.WSResponse;
import play.mvc.Http;

/**
 * Different ways of serializing a table row
 * 
 * @author Fabian Steeg (fsteeg)
 */
public enum TableRow {

	VALUES {
		@Override
		public String process(JsonNode doc, String property, String param,
				String label, List<String> values, Optional<List<String>> keys) {
			List<String> filtered =
					values.stream().filter(value -> !value.contains("http://dewey.info"))
							.collect(Collectors.toList());
			return filtered.isEmpty() ? ""
					: String.format("<tr><td>%s</td><td>%s</td></tr>", label,
							filtered.stream()
									.flatMap(s -> Arrays.asList(s.split("; ")).stream())
									.map(val -> label(doc, property, param, val, keys))
									.collect(Collectors.joining(
											property.equals("subjectChain") ? " <br/> " : " | ")));
		}

		private String label(JsonNode doc, String property, String param,
				String val, Optional<List<String>> labels) {
			String value = property.equals("subjectChain")
					? val.replaceAll("\\([\\d,]+\\)$", "").trim() : val;
			if (!labels.isPresent()) {
				String[] refAndLabel = refAndLabel(property, value, labels);
				return value.startsWith("http") ? String.format("<a title='%s' href='%s'>%s</a>",
						refAndLabel[0], refAndLabel[0], refAndLabel[1]) : refAndLabel[0];
			}
			String term = value;
			if (param.equals("q")) {
				term = "\"" + value + "\"";
			} else if (param.equals("raw")) {
				term = Application.rawQueryParam("", value);
			}
			try {
				term = URLEncoder.encode(term, "UTF-8");
			} catch (UnsupportedEncodingException e) {
				Logger.error("Could not call encode '{}'", term, e);
			}
			String search = String.format("/search?%s=%s", param, term);
			JsonNode node = doc.get(property);
			String label = labelForId(value, node, labels);
			String result = labels.get().contains("numbering") ? label
					: String.format(
							"<a title=\"Nach weiteren Titeln suchen\" href=\"%s\">%s</a>",
							search, label);
			if (value.startsWith("http")) {
				if (param.equals("agent")
						&& !value.contains("http://dewey.info")) {
					result += String.format(
							" <a title=\"Linked-Data-Quelle abrufen\" "
									+ "href=\"%s\"><span class=\"glyphicon glyphicon-link\"></span></a>",
							value);
				} else if (param.equals("subject")) {
					String topicSearch = String.format("/topics?q=%s", label);
					result += String.format(
							" <a title=\"Nach Themen mit '%s' suchen\" "
									+ "href=\"%s\"><span class=\"octicon octicon-ellipsis\"></span></a>",
							label, topicSearch);
				}
			}
			return result;
		}
	},
	VALUES_MULTI {
		@Override
		public String process(JsonNode doc, String property, String param,
				String label, List<String> values, Optional<List<String>> keys) {
			if (!keys.isPresent()) {
				throw new IllegalArgumentException("VALUES_MULTI needs valueLabels");
			}
			JsonNode node = doc.get(property).iterator().next();
			return values.stream()
					.filter(value -> !value.contains("http://dewey.info"))
					.map(val -> String.format("<tr><td>%s</td><td>%s</td></tr>", label,
							label(node, val, keys.get())))
					.collect(Collectors.joining("\n"));
		}

		private String label(JsonNode doc, String value, List<String> properties) {
			List<String> results = new ArrayList<>();
			List<String> resultValues = labelsFor(doc, value, properties);
			if (doc.get(properties.get(0)) != null) {
				JsonNode labelNode = doc.get(properties.get(0)).iterator().next().get("label");
				for (int i = 0; i < resultValues.size(); i++) {
					String currentValue = resultValues.get(i);
					String[] refAndLabel =
							refAndLabel(properties.get(i), currentValue, Optional.empty());
					String label = labelNode != null ? labelNode.textValue() : refAndLabel[1];
					String result =
							properties.get(i).equals("numbering") || value.equals("--")
							? currentValue
									: !value.startsWith("http") ? label : String.format(
											"<a title=\"Titeldetails anzeigen\" href=\"%s\">%s</a>",
											refAndLabel[0], label);
					results.add(result.replace("Band", "").trim());
				}
			}
			return results.stream().collect(Collectors.joining(", Band "));
		}

		private List<String> labelsFor(JsonNode doc, String value,
				List<String> keys) {
			List<String> result = new ArrayList<>();
			if (doc != null && doc.get(keys.get(0)) != null) {
				JsonNode node = doc.get(keys.get(0)).iterator().next();
				JsonNode id = node.get("id");
				JsonNode label = node.get("label");
				result.add(id != null ? id.textValue()
						: label != null ? label.textValue() : "--");
				JsonNode val = doc.get(keys.get(1));
				if (val != null)
					result.add(val.textValue());
			}
			return result.isEmpty() ? Arrays.asList(value) : result;
		}
	},
	LINKS {
		@Override
		public String process(JsonNode doc, String property, String param,
				String label, List<String> values, Optional<List<String>> labels) {
			return values.stream()
					.map(value -> String.format("<tr><td>%s</td><td>%s</td></tr>", label,
							link(property, value, labels)))
					.collect(Collectors.joining("\n"));
		}

		private String link(String property, String val,
				Optional<List<String>> labels) {
			String[] refAndLabel = refAndLabel(property, val, labels);
			String href = refAndLabel[0];
			String label = refAndLabel[1];
			return String.format("<a title='%s' href='%s'>%s</a>", href, href, label);
		}

	};

	/**
	 * @param id The ID
	 * @param doc The full document
	 * @param labelKeys Keys of the values to try as labels for the ID
	 * @return An HTML-escaped label for the ID
	 */
	public static String labelForId(String id, JsonNode doc,
			Optional<List<String>> labelKeys) {
		String label = "";
		if (id.startsWith("http://purl.org/lobid/rpb") || id.startsWith("https://rpb.lobid.org/spatial")) {
			label = String.format("%s (%s)", //
					Lobid.facetLabel(Arrays.asList(id), null, null),
					Classification.shortId(id));
		} else {
			label = graphObjectLabelForId(id, doc, labelKeys);
		}
		return HtmlEscapers.htmlEscaper().escape(label);
	}

	private static String graphObjectLabelForId(String id, JsonNode doc,
			Optional<List<String>> labelKeys) {
		if (!labelKeys.isPresent() || labelKeys.get().isEmpty() || doc == null) {
			return id;
		}

		for (JsonNode node :  doc ) {
			for (String key : labelKeys.get()) {
				String idField = node.has("id") ? "id" : "@id";
				if (node.has(key) && node.has(idField)
						&& node.get(idField).textValue().equals(id)) {
					JsonNode label = node.get(key);
					if (label != null && label.isTextual()
							&& !label.textValue().trim().isEmpty()) {
						return label.textValue() + lifeDates(node);
					}
				}
			}
		}
		return id;
	}

	private static String lifeDates(JsonNode node) {
		JsonNode birth = node.get("dateOfBirth");
		JsonNode death = node.get("dateOfDeath");
		if (birth != null) {
			return String.format(" (%s-%s)", birth.textValue(),
					death != null ? death.textValue() : "");
		}
		return "";
	}

	String[] refAndLabel(String property, String value,
			Optional<List<String>> labels) {
		value = rpbUrlIfInRpb(value);
		if ((property.equals("containedIn") || property.equals("hasPart")
				|| property.equals("isPartOf") || property.equals("hasSuperordinate")
				|| property.equals("bibliographicCitation")) && value.contains("lobid.org")) {
			return new String[] { value.contains("rpb") // replaced via rpbUrlIfInRpb()
					? value.replaceAll("http.+/", "/") // full URL -> relative link
					: value, Lobid.resourceLabel(value) };
		}
		String label =
				labels.isPresent() && labels.get().size() > 0 ? labels.get().get(0)
						: value.startsWith("http") ? URI.create(value).getHost() : value;
		return new String[] { value, label };
	}

	public String rppdUrlIfInRppd(String value) {
		if (!value.contains("d-nb.info/gnd/")) {
			return value;
		}
		String rppdUrl = value.replaceAll("https?://d-nb.info/gnd/([^#]+)", "https://rppd.lobid.org/$1");
		int status = WS.url(rppdUrl).get().map(WSResponse::getStatus).get(Lobid.API_TIMEOUT);
		return status == Http.Status.OK ? rppdUrl : value;
	}

	public String rpbUrlIfInRpb(String value) {
		if(!(value.contains("lobid.org/resources/") || value.contains("cbsopac.rz.uni-frankfurt.de"))) {
			return value;
		}
		value = value.replace("http://cbsopac.rz.uni-frankfurt.de/DB=2.1/PPNSET?PPN=", "https://lobid.org/resources/");
		String rpbUrl = value.replaceAll("https?://lobid.org/resources/([^#]+)(#!)", CONFIG.getString("host") + "/$1");
		WSRequest rpbRequest = WS.url(rpbUrl).setQueryParameter("format", "json");
		JsonNode rpbJson = rpbRequest.get().map(WSResponse::asJson).get(Lobid.API_TIMEOUT);
		return rpbJson.get("member").elements().hasNext() ? rpbUrl : rpbUrlIfhasRpbId(value);
	}

	String rpbUrlIfhasRpbId(String value) {
		WSRequest lobidRequest = WS.url(value).setHeader("Content-Type", "application/json");
		JsonNode lobidJson = lobidRequest.get().map(WSResponse::asJson).get(Lobid.API_TIMEOUT);
		return lobidJson.has("rpbId") ? CONFIG.getString("host") + "/" + lobidJson.get("rpbId").textValue() : value;
	}

	public abstract String process(JsonNode doc, String property, String param,
			String label, List<String> values, Optional<List<String>> labels);
}

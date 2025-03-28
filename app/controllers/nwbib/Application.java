/* Copyright 2014 Fabian Steeg, hbz. Licensed under the GPLv2 */

package controllers.nwbib;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.text.Collator;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.SortedSet;
import java.util.Spliterators;
import java.util.TreeSet;
import java.util.UUID;
import java.util.function.Function;
import java.util.function.Predicate;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import java.util.stream.StreamSupport;

import org.antlr.runtime.RecognitionException;
import org.apache.commons.io.IOUtils;
import org.apache.commons.lang3.tuple.Pair;
import org.elasticsearch.common.geo.GeoPoint;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.type.MapType;
import com.fasterxml.jackson.databind.type.TypeFactory;
import com.typesafe.config.Config;
import com.typesafe.config.ConfigFactory;

import controllers.nwbib.Classification.Type;
import play.Logger;
import play.Play;
import play.cache.Cache;
import play.cache.Cached;
import play.data.Form;
import play.libs.F.Promise;
import play.libs.Json;
import play.libs.ws.WS;
import play.libs.ws.WSRequest;
import play.libs.ws.WSResponse;
import play.mvc.Controller;
import play.mvc.Http;
import play.mvc.Result;
import play.mvc.Results;
import play.twirl.api.HtmlFormat;
import rpb.ETL;
import views.html.browse_classification;
import views.html.browse_register;
import views.html.classification;
import views.html.details;
import views.html.index;
import views.html.info;
import views.html.register;
import views.html.search;
import views.html.stars;

/**
 * The main application controller.
 * 
 * @author Fabian Steeg (fsteeg)
 */
public class Application extends Controller {

	private static final String UTF_8 = "UTF-8";

	static final int MAX_FACETS = 150;

	private static final String STARRED = "starred";

	/** The internal ES field for the type facet. */
	public static final String TYPE_FIELD = "type";
	/** The internal ES field for the medium facet. */
	public static final String MEDIUM_FIELD = "medium.id";
	/** The internal ES field for the item/exemplar facet. */
	public static final String ITEM_FIELD = "owner";

	/** The internal ES field for the RPB subject facet. */
	public static final String RPB_SUBJECT_FIELD = "subject.id<rpb#";
	/** The internal ES field for the NWBib spatial facet. */
	public static final String NWBIB_SPATIAL_FIELD = "spatial.id<spatial#";
	/** The internal ES field for the coverage facet. */
	public static final String COVERAGE_FIELD = "spatial.label.raw";
	/** The internal ES field for subject locations. */
	public static final String SUBJECT_LOCATION_FIELD = "spatial.focus.geo";

	/** The internal ES field for subjects. */
	public static final String SUBJECT_FIELD = "subject.componentList.id";

	/** The internal ES field for issued years. */
	public static final String ISSUED_FIELD = "publication.startDate";

	private static final File FILE = new File("conf/nwbib.conf");
	/** Access to the nwbib.conf config file. */
	public final static Config CONFIG = ConfigFactory
			.parseFile(
					FILE.exists() ? FILE : new File("modules/nwbib/conf/nwbib.conf"))
			.resolve();

	static Form<String> queryForm = Form.form(String.class);

	static final int ONE_HOUR = 60 * 60;
	/** The number of seconds in one day. */
	public static final int ONE_DAY = 24 * ONE_HOUR;

	/** The prefix for zdbId-based lobid URLs. */
	public static final String ZDB_PREFIX = "ZDB-";

	/**
	 * @param map The scope for the NRW map ("kreise" or "gemeinden")
	 * @return The NWBib index page.
	 */
	public static Result index(String map) {
		final Form<String> form = queryForm.bindFromRequest();
		if (form.hasErrors())
			return badRequest(index.render(map));
		return ok(index.render(map));
	}

	/**
	 * @return The NWBib info page.
	 */
	@Cached(key = "nwbib.info", duration = ONE_HOUR)
	public static Result info() {
		return ok(info.render());
	}

	/**
	 * @return The NWBib advanced search page.
	 */
	@Cached(key = "nwbib.advanced", duration = ONE_HOUR)
	public static Result advanced() {
		return ok(views.html.advanced.render());
	}

	/**
	 * @return The current full URI, URL-encoded, or null.
	 */
	public static String currentUri() {
		try {
			return URLEncoder.encode(request().host() + request().uri(), UTF_8);
		} catch (UnsupportedEncodingException e) {
			Logger.error("Could not get current URI", e);
		}
		return null;
	}

	/**
	 * @param q The topics query.
	 * @return The NWBib topics search page.
	 */
	public static Promise<Result> topics(String q) {
		if (q.isEmpty())
			return Promise.promise(
					() -> ok(views.html.topics.render(q, Collections.emptyList())));
		String cacheId = "topics." + q;
		@SuppressWarnings("unchecked")
		Promise<Result> cachedResult = (Promise<Result>) Cache.get(cacheId);
		if (cachedResult != null)
			return cachedResult;
		String aggregationField = "subject.label.raw";
		WSRequest request = // @formatter:off
				WS.url(Application.CONFIG.getString("nwbib.api"))
						.setHeader("Accept", "application/json")
						.setQueryParameter("subject", q)
						.setQueryParameter("aggregations", aggregationField)
						.setQueryParameter("filter", Application.CONFIG.getString("nwbib.filter"))
						.setQueryParameter("from", "0")
						.setQueryParameter("size", "1"); // @formatter:on
		Promise<Result> result = request.get().map((WSResponse response) -> {
			if (response.getStatus() == Http.Status.OK) {
				Iterator<JsonNode> jsonIterator =
						response.asJson().findValue(aggregationField).elements();
				Stream<JsonNode> jsonStream = StreamSupport.stream(
						Spliterators.spliteratorUnknownSize(jsonIterator, 0), false);
				return ok(views.html.topics.render(q, cleanSortUnique(jsonStream, q)));
			}
			Logger.error(new String(response.asByteArray()));
			return ok(views.html.topics.render(q, Collections.emptyList()));
		});
		cacheOnRedeem(cacheId, result, ONE_HOUR);
		return result;
	}

	private static List<Pair<String, String>> cleanSortUnique(
			Stream<JsonNode> topics, String q) {
		Function<JsonNode, Pair<String, String>> mapper = topic -> {
			String key =
					topic.get("key").textValue().replaceAll("\\([\\d,]+\\)$", "");
			Number count = topic.get("doc_count").numberValue();
			return Pair.of(key, count.toString());
		};
		Predicate<Pair<String, String>> filter = topic -> {
			String key = topic.getLeft().trim();
			return Arrays.asList(q.split("[ -]")).stream()
					.filter((String e) -> key.toLowerCase().contains(e.toLowerCase()))
					.count() > 0 && !key.startsWith(":") && !key.startsWith(".");
		};
		Comparator<Pair<String, String>> sorter = (s1, s2) -> Collator
				.getInstance(Locale.GERMAN).compare(s1.getLeft(), s2.getLeft());
		List<Pair<String, String>> filtered =
				topics.map(mapper).filter(filter).collect(Collectors.toList());
		SortedSet<Pair<String, String>> sortedUnique = new TreeSet<>(sorter);
		sortedUnique.addAll(filtered);
		return new ArrayList<>(sortedUnique);
	}

	/**
	 * @param q Query to search in all fields
	 * @param person Query for a person associated with the resource
	 * @param name Query for the resource name (title)
	 * @param subject Query for the resource subject
	 * @param id Query for the resource id
	 * @param publisher Query for the resource publisher
	 * @param issued Query for the resource issued year
	 * @param medium Query for the resource medium
	 * @param rpbspatial Query for the resource rpbspatial classification
	 * @param rpbsubject Query for the resource rpbsubject classification
	 * @param from The page start (offset of page of resource to return)
	 * @param size The page size (size of page of resource to return)
	 * @param owner Owner filter for resource queries
	 * @param t Type filter for resource queries
	 * @param sort Sorting order for results ("newest", "oldest", "" -> relevance)
	 * @param details If true, render details
	 * @param location A polygon describing the subject area of the resources
	 * @param word A word, a concept from the hbz union catalog
	 * @param corporation A corporation associated with the resource
	 * @param raw A query string that's directly (unprocessed) passed to ES
	 * @param format The response format, 'html' (default) or 'json'
	 * @return The search results
	 */
	public static Promise<Result> search(final String q, final String person,
			final String name, final String subject, final String id,
			final String publisher, final String issued, final String medium,
			final String rpbspatial, final String rpbsubject, final int from,
			final int size, final String owner, String t, String sort,
			boolean details, String location, String word, String corporation,
			String raw, String format) {
		response().setHeader("Access-Control-Allow-Origin", "*");
		String uuid = session("uuid");
		if (uuid == null)
			session("uuid", UUID.randomUUID().toString());
		if (!q.contains("hbzId:")) {
			session("lastSearchUrl", request().uri());
			response().setHeader("Cache-Control",
					"no-cache, no-store, must-revalidate");
			response().setHeader("Pragma", "no-cache");
			response().setHeader("Expires", "0");
		}
		String cacheId = request().queryString().isEmpty() ? request().uri()
				: String.format("%s-%s", uuid, request().uri());
		@SuppressWarnings("unchecked")
		Promise<Result> cachedResult = (Promise<Result>) Cache.get(cacheId);
		if (cachedResult != null)
			return cachedResult;
		Logger.debug("Not cached: {}, will cache for one hour", cacheId);
		final Form<String> form = queryForm.bindFromRequest();
		if (form.hasErrors())
			return Promise.promise(
					() -> badRequest(search.render(null, q, person, name, subject, id,
							publisher, issued, medium, rpbspatial, rpbsubject, from, size,
							0L, owner, t, sort, location, word, corporation, raw)));
		String query = form.data().get("q");
		Promise<Result> result = okPromise(query != null ? query : q, person, name,
				subject, id, publisher, issued, medium, rpbspatial, rpbsubject,
				from, size, owner, t, sort, details, location, word, corporation, raw,
				format.isEmpty() ? "html" : format);
		cacheOnRedeem(cacheId, result, ONE_HOUR);
		return result;
	}

	public static Promise<Result> searchSpatial(final String id, final int from, final int size,
			final String format) {
		return Promise.pure(found(routes.Application.search("", "", "", "", "", "", "", "",
				"https://rpb.lobid.org/spatial#n" + id, "", from, size, "", "", "", false, "", "",
				"", "", format)));
	}

	public static Promise<Result> showPl(String name, String db, int index, int zeilen, String s1) {
		String url = db.equals("rpb") ? "https://rpb.lbz-rlp.de/" : "https://rppd.lobid.org/";
		return Promise
				.pure(ok("<head><meta http-equiv='Refresh' content='0; URL=" + url
						+ HtmlFormat.escape(s1) + "'/></head>").as("text/html"));
	}

	/**
	 * @param id The resource ID.
	 * @param format The requested resource format (html, json).
	 * @return The details page for the resource with the given ID.
	 */
	public static Promise<Result> show(final String id, final String format) {
		String prevNext = (String) Cache.get(session("uuid") + "-" + id);
		if (prevNext != null) {
			session("prev", prevNext.startsWith(",") ? "" : prevNext.split(",")[0]);
			session("next", prevNext.endsWith(",") ? "" : prevNext.split(",")[1]);
		} else {
			Logger.warn("No pagination session data for {}", id);
		}
		String cleanId = id.replace("#!", "").replace(ZDB_PREFIX, "");
		String q = String.format("rpbId:%s OR hbzId:%s OR almaMmsId:%s OR zdbId:%s OR id:\"https://lobid.org/resources/%s\"",
				cleanId, cleanId, cleanId, cleanId, cleanId);
		return search(q,"", "", "", "", "", "", "", "", "", 0, 1, "", "", "", "".equals(format) || "html".equals(format),
				"", "", "", "", format);
	}

	/**
	 * @param t The register type ("Raumsystematik" or "Sachsystematik")
	 * @return The alphabetical register for the given classification type
	 */
	public static Result register(final String t) {
		Result cachedResult = (Result) Cache.get("register." + t);
		if (cachedResult != null)
			return cachedResult;
		Result result = null;
		if (t.isEmpty()) {
			result = ok(register.render());
		} else {
			Type classification = Classification.Type.from(t);
			if (classification == null) {
				Logger.error("Failed to get data for register type: " + t);
				flashError();
				return internalServerError(browse_register.render(null, t, ""));
			}
			JsonNode sorted = classification.buildRegister();
			String placeholder = "Register zur " + t + " filtern";
			result = ok(browse_register.render(sorted.toString(), t, placeholder));
		}
		Cache.set("result." + t, result);
		return result;
	}

	/**
	 * @return A list of nwbib journals
	 * @throws IOException If reading the journals list data fails
	 */
	@Cached(key = "journals", duration = ONE_DAY)
	public static Result journals() throws IOException {
		try (InputStream stream = Play.application().classloader()
				.getResourceAsStream("nwbib-journals.csv")) {
			String csv = IOUtils.toString(stream, UTF_8);
			List<String> lines = Arrays.asList(csv.split("\n"));
			List<HashMap<String, String>> maps = lines.stream()
					.filter(line -> line.split("\",\"").length == 2).map(line -> {
						HashMap<String, String> map = new HashMap<>();
						String[] strings = line.split("\",\"");
						map.put("label", strings[0].replace("\"\"", "'").replace("\"", ""));
						map.put("value", strings[1].replace("\"", ""));
						return map;
					}).collect(Collectors.toList());
			String journals = Json.toJson(maps).toString();
			return ok(browse_register.render(journals, "Zeitschriften",
					"Zeitschriftenliste filtern"));
		}
	}

	/**
	 * @param t The register type ("Raumsystematik" or "Sachsystematik")
	 * @return Classification data for the given type
	 */
	public static Result classification(final String t) {
		if (t.equals("WikidataImport")) {
			File data = WikidataLocations.wikidataFile();
			boolean deleteSuccess = data.delete();
			Logger.debug("Deleting local data: {}, success: {}", data, deleteSuccess);
			return redirect(routes.Application.classification("Wikidata"));
		}
		Result cachedResult = (Result) Cache.get("classification." + t);
		if (cachedResult != null)
			return cachedResult;
		Result result = null;
		String placeholder = t + " filtern";
		if (t.equals("Wikidata")) {
			return classificationResultWikidata(t, placeholder);
		}
		if (t.isEmpty()) {
			result = ok(classification.render());
		} else {
			if (Classification.Type.from(t) == null) {
				Logger.error("Failed to get data for classification type: " + t);
				flashError();
				return internalServerError(
						browse_classification.render(null, null, t, ""));
			}
			result = classificationResult(t, placeholder);
		}
		Cache.set("classification." + t, result, ONE_DAY);
		return result;
	}

	/**
	 * @param t The register type ("Raumsystematik" or "Sachsystematik")
	 * @return Classification data for the given type
	 */
	public static Result download(final String t) {
		Result cachedResult = (Result) Cache.get("download." + t);
		if (cachedResult != null)
			return cachedResult;
		Result result = null;
		if (t.isEmpty()) {
			Results.badRequest("Bad request: empty t");
		} else {
			if (Classification.Type.from(t) == null) {
				Logger.error("Failed to get data for classification type: " + t);
				return internalServerError(
						browse_classification.render(null, null, t, ""));
			}
			response().setContentType("application/x-download");
			String filename =
					t.equals("Raumsystematik") ? "rpb-spatial.ttl" : "rpb.ttl";
			response().setHeader("Content-disposition",
					"attachment; filename=" + filename);
			try {
				return ok(new URL(CONFIG
						.getString(t.equals("Raumsystematik") ? "index.data.rpbspatial"
								: "index.data.rpbsubject")).openStream());
			} catch (IOException e) {
				e.printStackTrace();
				return internalServerError(e.getMessage());
			}
		}
		Cache.set("download." + t, result);
		return result;
	}

	/**
	 * @param t The data type: classification, register, or download
	 * @return Classification data for "Raumsystematik"
	 */
	public static Result spatial(String t) {
		return classificationResponse(t, "Raumsystematik");
	}

	/**
	 * @return TTL classification data for "Raumsystematik"
	 */
	public static Result spatialTtl() {
		return classificationResponse("download", "Raumsystematik");
	}

	/**
	 * @param t The data type: classification, register, or download
	 * @return Classification data for "Sachsystematik"
	 */
	public static Result subjects(String t) {
		return classificationResponse(t, "Sachsystematik");
	}

	/**
	 * @return TTL classification data for "Sachsystematik"
	 */
	public static Result subjectsTtl() {
		return classificationResponse("download", "Sachsystematik");
	}

	private static Result classificationResponse(String t, String data) {
		switch (t) {
		case "classification":
			return classification(data);
		case "register":
			return register(data);
		case "download":
			return download(data);
		default:
			return Results.badRequest("Bad request: t=" + t + " unsupported");
		}
	}

	// Admin UI for reloading classification from Wikidata
	private static Result classificationResultWikidata(String t,
			String placeholder) {
		Pair<List<JsonNode>, Map<String, List<JsonNode>>> topAndSub =
				Classification.Type.SPATIAL.buildHierarchy();
		String topClassesJson = Json.toJson(topAndSub.getLeft()).toString();
		return ok(browse_classification.render(topClassesJson, topAndSub.getRight(),
				t, placeholder));
	}

	private static Result classificationResult(String t, String placeholder) {
		Pair<List<JsonNode>, Map<String, List<JsonNode>>> topAndSub =
				Classification.Type.from(t).buildHierarchy();
		String topClassesJson = Json.toJson(topAndSub.getLeft()).toString();
		return ok(browse_classification.render(topClassesJson, topAndSub.getRight(),
				t, placeholder));
	}

	private static Promise<Result> okPromise(final String q, final String person,
			final String name, final String subject, final String id,
			final String publisher, final String issued, final String medium,
			final String rpbspatial, final String rpbsubject, final int from,
			final int size, final String owner, String t, String sort,
			boolean details, String location, String word, String corporation,
			String raw, String format) {
		final Promise<Result> result = call(q, person, name, subject, id, publisher,
				issued, medium, rpbspatial, rpbsubject, from, size, owner, t, sort,
				details, location, word, corporation, raw, format);
		return result.recover((Throwable throwable) -> {
			Logger.error("Error on Lobid call with q={}, person={}, name={}, subject={}, id={}, publisher={},\n"
					+ "issued={}, medium={}, rpbspatial={}, rpbsubject={}, from={}, size={}, owner={}, t={}, sort={},\n"
					+ "details={}, location={}, word={}, corporation={}, raw={}, format={}", //
					q, person, name, subject, id, publisher, issued, medium, rpbspatial, rpbsubject, from, size, owner,
					t, sort, details, location, word, corporation, raw, format);
			Logger.error("Could not call Lobid", throwable);
			flashError();
			return internalServerError(search.render("[]", q, person, name, subject,
					id, publisher, issued, medium, rpbspatial, rpbsubject, from, size,
					0L, owner, t, sort, location, word, corporation, raw));
		});
	}

	private static void flashError() {
		flash("error",
				"Es ist ein Fehler aufgetreten. "
						+ "Bitte versuchen Sie es erneut oder kontaktieren Sie das "
						+ "Entwicklerteam, falls das Problem fortbesteht "
						+ "(siehe Link 'Feedback' oben rechts).");
	}

	private static void cacheOnRedeem(final String cacheId,
			final Promise<Result> resultPromise, final int duration) {
		resultPromise.onRedeem((Result result) -> {
			if (result.status() == Http.Status.OK)
				Cache.set(cacheId, resultPromise, duration);
		});
	}

	static Promise<Result> call(final String q, final String person,
			final String name, final String subject, final String id,
			final String publisher, final String issued, final String medium,
			final String rpbspatial, final String rpbsubject, final int from,
			final int size, String owner, String t, String sort, boolean showDetails,
			String location, String word, String corporation, String raw,
			String format) {
		final WSRequest requestHolder = Lobid.request(q, person, name, subject, id,
				publisher, issued, medium, rpbspatial, rpbsubject, from, size,
				owner, t, sort, location, word, corporation, raw);
		return requestHolder.get().map((WSResponse response) -> {
			Long hits = 0L;
			String s = "{}";
			if (response.getStatus() == Http.Status.OK) {
				JsonNode json = response.asJson();
				hits = Lobid.getTotalResults(json);
				s = json.toString();
				if (!q.contains("hbzId:")) {
					List<JsonNode> ids = json.findValues("hbzId");
					uncache(
							ids.stream().map(j -> j.asText()).collect(Collectors.toList()));
					Cache.set(session("uuid") + "-lastSearch", ids.toString(), ONE_DAY);
				}
			} else {
				Logger.warn("{}: {} ({}, {})", response.getStatus(),
						response.getStatusText(), requestHolder.getUrl(),
						requestHolder.getQueryParameters());
			}
			if (showDetails) {
				String json = "";
				JsonNode nodes = Json.parse(s).get("member");
				if (nodes != null && nodes.isArray() && nodes.size() == 1) {
					json = nodes.get(0).toString();
				} else {
					Logger.warn("No suitable data to show details for: {}", nodes);
				}
				return ok(details.render(CONFIG, json, id));
			}

			return format.equals("html")
					? ok(search.render(s, q, person, name, subject, id, publisher, issued,
							medium, rpbspatial, rpbsubject, from, size, hits, owner, t,
							sort, location, word, corporation, raw))
					: ok(new ObjectMapper().writerWithDefaultPrettyPrinter()
							.writeValueAsString(Json.parse(s)))
									.as("application/json; charset=utf-8");
		});
	}

	private static void uncache(List<String> ids) {
		for (String id : ids) {
			Cache.remove(String.format("%s-/nwbib/%s", session("uuid"), id));
		}
	}

	/**
	 * @param q Query to search in all fields
	 * @param person Query for a person associated with the resource
	 * @param name Query for the resource name (title)
	 * @param subject Query for the resource subject
	 * @param id Query for the resource id
	 * @param publisher Query for the resource publisher
	 * @param issued Query for the resource issued year
	 * @param medium Query for the resource medium
	 * @param rpbspatial Query for the resource rpbspatial classification
	 * @param rpbsubject Query for the resource rpbsubject classification
	 * @param from The page start (offset of page of resource to return)
	 * @param size The page size (size of page of resource to return)
	 * @param owner Owner filter for resource queries
	 * @param t Type filter for resource queries
	 * @param field The facet field (the field to facet over)
	 * @param sort Sorting order for results ("newest", "oldest", "" -> relevance)
	 * @param location A polygon describing the subject area of the resources
	 * @param word A word, a concept from the hbz union catalog
	 * @param corporation A corporation associated with the resource
	 * @param raw A query string that's directly (unprocessed) passed to ES
	 * @return The search results
	 */
	public static Promise<Result> facets(String q, String person, String name,
			String subject, String id, String publisher, String issued, String medium,
			String rpbspatial, String rpbsubject, int from, int size,
			String owner, String t, String field, String sort, String location,
			String word, String corporation, String raw) {

		String key = String.format(
				"facets.%s.%s.%s.%s.%s.%s.%s.%s.%s.%s.%s.%s.%s.%s.%s.%s.%s", field, q,
				person, name, id, publisher, location, word, corporation, raw, subject,
				issued, medium, rpbspatial, rpbsubject, owner, t);
		Result cachedResult = (Result) Cache.get(key);
		if (cachedResult != null) {
			return Promise.promise(() -> cachedResult);
		}

		String labelTemplate = "<span class='%s'/>&nbsp;%s (%s)";

		Function<JsonNode, Pair<JsonNode, String>> toLabel = json -> {
			String term = json.get("key").asText();
			int count = json.get("doc_count").asInt();
			String icon = Lobid.facetIcon(Arrays.asList(term), field);
			String label = Lobid.facetLabel(Arrays.asList(term), field, "");
			String fullLabel = String.format(labelTemplate, icon, label, count);
			return Pair.of(json, fullLabel);
		};

		Predicate<Pair<JsonNode, String>> labelled = pair -> {
			JsonNode json = pair.getLeft();
			String label = pair.getRight();
			int count = json.get("doc_count").asInt();
			return (!label.contains("http") && !label.contains("_:")) && label
					.length() > String.format(labelTemplate, "", "", count).length();
		};

		Collator collator = Collator.getInstance(Locale.GERMAN);
		Comparator<Pair<JsonNode, String>> sorter = (p1, p2) -> {
			String t1 = p1.getLeft().get("key").asText();
			String t2 = p2.getLeft().get("key").asText();
			boolean t1Current = current(subject, medium, rpbspatial, rpbsubject,
					owner, t, field, t1, raw);
			boolean t2Current = current(subject, medium, rpbspatial, rpbsubject,
					owner, t, field, t2, raw);
			if (t1Current == t2Current) {
				if (!field.equals(ISSUED_FIELD)) {
					Integer c1 = p1.getLeft().get("doc_count").asInt();
					Integer c2 = p2.getLeft().get("doc_count").asInt();
					return c2.compareTo(c1);
				}
				String l1 = p1.getRight().substring(p1.getRight().lastIndexOf('>') + 1);
				String l2 = p2.getRight().substring(p2.getRight().lastIndexOf('>') + 1);
				return collator.compare(l1, l2);
			}
			return t1Current ? -1 : t2Current ? 1 : 0;
		};

		Function<Pair<JsonNode, String>, String> toHtml = pair -> {
			JsonNode json = pair.getLeft();
			String fullLabel = pair.getRight();
			String term = json.get("key").asText();
			if (field.equals(SUBJECT_LOCATION_FIELD)) {
				GeoPoint point = new GeoPoint(term);
				term = String.format("%s,%s", point.getLat(), point.getLon());
			}
			String mediumQuery = !field.equals(MEDIUM_FIELD) ? medium //
					: queryParam(medium, term);
			String typeQuery = !field.equals(TYPE_FIELD) ? t //
					: queryParam(t, term);
			String ownerQuery = !field.equals(ITEM_FIELD) ? owner //
					: withoutAndOperator(queryParam(owner, term));
			String rpbsubjectQuery =
					!field.equals(RPB_SUBJECT_FIELD) ? rpbsubject //
							: queryParam(rpbsubject, term);
			String rpbspatialQuery =
					!field.equals(NWBIB_SPATIAL_FIELD) ? rpbspatial //
							: queryParam(rpbspatial, term);
			String rawQuery = !field.equals(COVERAGE_FIELD) ? raw //
					: rawQueryParam(raw, term);
			String locationQuery = !field.equals(SUBJECT_LOCATION_FIELD) ? location //
					: term;
			String subjectQuery = !field.equals(SUBJECT_FIELD) ? subject //
					: queryParam(subject, term);
			String issuedQuery = !field.equals(ISSUED_FIELD) ? issued //
					: queryParam(issued, term);

			boolean current = current(subject, medium, rpbspatial, rpbsubject,
					owner, t, field, term, raw);
			String routeUrl = routes.Application.search(q, person, name, subjectQuery,
					id, publisher, issuedQuery, mediumQuery, rpbspatialQuery,
					rpbsubjectQuery, from, size, ownerQuery, typeQuery,
					sort(sort, rpbspatialQuery, rpbsubjectQuery, subjectQuery), false,
					locationQuery, word, corporation, rawQuery, "").url();

			String result = String.format(
					"<li " + (current ? "class=\"active\"" : "")
							+ "><a class=\"%s-facet-link\" href='%s'>"
							+ "<label for=\"%s\"><input id=\"%s\" onclick=\"location.href='%s'\" class=\"facet-checkbox\" "
							+ "type=\"checkbox\" %s>&nbsp;%s</input></label>" + "</a></li>",
					Math.abs(field.hashCode()), routeUrl, routeUrl, routeUrl, routeUrl,
					current ? "checked" : "", fullLabel);

			return result;
		};

		Promise<Result> promise = Lobid.getFacets(q, person, name, subject, id,
				publisher, issued, medium, rpbspatial, rpbsubject, owner, field, t,
				location, word, corporation, raw).map(json -> {
					Stream<JsonNode> stream = StreamSupport.stream(
							Spliterators.spliteratorUnknownSize(json.findValue("aggregation")
									.get(field.split("<")[0]).elements(), 0),
							false);
					if (field.equals(RPB_SUBJECT_FIELD)
							|| field.equals(NWBIB_SPATIAL_FIELD)) {
						String source = field.split("<")[1];
						stream = stream
								.filter(aggr -> aggr.get("key").textValue().contains(source));
					}
					String labelKey = String.format(
							"facets-labels.%s.%s.%s.%s.%s.%s.%s.%s.%s.%s.%s.%s.%s.%s.%s.%s.%s.%s",
							field, raw, q, person, name, id, publisher, word, corporation,
							subject, issued, medium, rpbspatial, rpbsubject, raw,
							field.equals(ITEM_FIELD) ? "" : owner, t, location);

					@SuppressWarnings("unchecked")
					List<Pair<JsonNode, String>> labelledFacets =
							(List<Pair<JsonNode, String>>) Cache.get(labelKey);
					if (labelledFacets == null) {
						labelledFacets = stream.map(toLabel).filter(labelled)
								.collect(Collectors.toList());
						Cache.set(labelKey, labelledFacets, ONE_DAY);
					}
					return labelledFacets.stream().sorted(sorter).map(toHtml)
							.collect(Collectors.toList());
				}).map(lis -> ok(String.join("\n", lis)));
		promise.onRedeem(r -> Cache.set(key, r, ONE_DAY));
		return promise;
	}

	private static String sort(String sort, String rpbspatialQuery,
			String rpbsubjectQuery, String subjectQuery) {
		return (rpbspatialQuery + rpbsubjectQuery + subjectQuery).contains(",")
				? ""
				/* relevance */ : sort;
	}

	private static boolean current(String subject, String medium,
			String rpbspatial, String rpbsubject, String owner, String t,
			String field, String term, String raw) {
		return field.equals(MEDIUM_FIELD) && contains(medium, term)
				|| field.equals(TYPE_FIELD) && contains(t, term)
				|| field.equals(ITEM_FIELD) && contains(owner, term)
				|| field.equals(NWBIB_SPATIAL_FIELD) && contains(rpbspatial, term)
				|| field.equals(COVERAGE_FIELD) && rawContains(raw, quotedEscaped(term))
				|| field.equals(RPB_SUBJECT_FIELD) && contains(rpbsubject, term)
				|| field.equals(SUBJECT_FIELD) && contains(subject, term);
	}

	private static boolean contains(String value, String term) {
		return Arrays.asList(value.split(",")).contains(term);
	}

	private static String queryParam(String currentParam, String term) {
		if (currentParam.isEmpty())
			return term;
		else if (contains(currentParam, term)) {
			String termRemoved = currentParam.replace(term, "")
					.replaceAll("\\A,|,?\\z", "").replaceAll(",+", ",");
			return termRemoved.equals("AND") ? "" : termRemoved;
		} else
			return withoutAndOperator(currentParam) + "," + term + ",AND";
	}

	private static String withoutAndOperator(String currentParam) {
		return currentParam.replace(",AND", "");
	}

	/**
	 * @param currentParam The current value of the query param
	 * @param term The term to create a query for
	 * @return The escaped Elasticsearch query string for the `raw` query param
	 */
	public static String rawQueryParam(String currentParam, String term) {
		String rawPrefix =
				Lobid.escapeUri(COVERAGE_FIELD.replace(".raw", "")) + ":";
		if (currentParam.isEmpty()) {
			return rawPrefix + "(+" + quotedEscaped(term) + ")";
		} else if (rawContains(currentParam, quotedEscaped(term))) {
			String removedTerm = currentParam.replace(rawPrefix, "")
					.replace("+" + quotedEscaped(term), "")
					.replaceAll("\\A\\+|\\+\\z", "").replaceAll("\\++", "+");
			return removedTerm.trim().equals("()") ? "" : rawPrefix + removedTerm;
		} else
			return currentParam.substring(0, currentParam.length() - 1) + "+"
					+ quotedEscaped(term) + ")";
	}

	private static String quotedEscaped(String term) {
		return "\"" + Lobid.escapeUri(term) + "\"";
	}

	private static boolean rawContains(String raw, String term) {
		String[] split = raw.split(":");
		String terms = split[split.length - 1];
		terms =
				terms.length() >= 2 ? terms.substring(1, terms.length() - 1) : terms;
		return Arrays.asList(terms.split("\\+")).contains(term);
	}

	/**
	 * @param id The resource ID
	 * @return True, if the resource with given ID is starred by the user
	 */
	public static boolean isStarred(String id) {
		return starredIds().contains(id);
	}

	/**
	 * @param id The resource ID to star
	 * @return An OK result
	 */
	public static Result star(String id) {
		String starred = currentlyStarred();
		if (!starred.contains(id)) {
			session(STARRED, starred + " " + id);
			uncache(Arrays.asList(id));
			uncacheLastSearchUrl();
		}
		return ok("Starred: " + id);
	}

	/**
	 * @param ids The resource IDs to star
	 * @return A 303 SEE_OTHER result to the referrer
	 */
	public static Result starAll(String ids) {
		Arrays.asList(ids.split(",")).forEach(id -> star(id));
		return seeOther(request().getHeader(REFERER));
	}

	/**
	 * @param id The resource ID to unstar
	 * @return An OK result
	 */
	public static Result unstar(String id) {
		List<String> starred = starredIds();
		starred.remove(id);
		session(STARRED, String.join(" ", starred));
		uncache(Arrays.asList(id));
		uncacheLastSearchUrl();
		return ok("Unstarred: " + id);
	}

	private static void uncacheLastSearchUrl() {
		String lastSearchUrl = session("lastSearchUrl");
		if (lastSearchUrl != null)
			Cache.remove(session("uuid") + "-" + lastSearchUrl);
	}

	/**
	 * @param format The format to show the current stars in
	 * @param ids Comma-separated IDs to show, of empty string
	 * @return A page with all resources starred by the user
	 */
	public static Promise<Result> showStars(String format, String ids) {
		uncacheLastSearchUrl();
		final List<String> starred = starredIds();
		if (ids.isEmpty() && !starred.isEmpty()) {
			return Promise.pure(redirect(routes.Application.showStars(format,
					starred.stream().collect(Collectors.joining(",")))));
		}
		final List<String> starredIds =
				starred.isEmpty() && ids.trim().isEmpty() ? starred
						: Arrays.asList(ids.split(","));
		String cacheKey = "starsForIds." + starredIds;
		Object cachedJson = Cache.get(cacheKey);
		if (cachedJson != null && cachedJson instanceof List) {
			@SuppressWarnings("unchecked")
			List<JsonNode> json = (List<JsonNode>) cachedJson;
			return Promise.pure(ok(stars.render(starredIds, json, format)));
		}
		Stream<Promise<JsonNode>> promises = starredIds.stream()
				.map(id -> WS
						.url(String
								.format(String.format(CONFIG.getString("indexUrlFormat"), id)))
						.setContentType("application/json").get()
						.map(response -> response.asJson().get("member").get(0)));
		return Promise.sequence(promises.collect(Collectors.toList()))
				.map((List<JsonNode> vals) -> {
					uncache(starredIds);
					session("lastSearchUrl",
							routes.Application.showStars(format, ids).toString());
					Cache.set(session("uuid") + "-lastSearch",
							starredIds.stream().map(s -> "\"" + s + "\"")
									.collect(Collectors.toList()).toString(),
							Application.ONE_DAY);
					Cache.set(cacheKey, vals, ONE_DAY);
					return ok(stars.render(starredIds, vals, format));
				});
	}

	public static Promise<Result> showSw(String rpbId) {
		String strapiUrl = "https://rpb-cms.lobid.org/admin/content-manager/collection-types/"
				+ "api::rpb-authority.rpb-authority?filters[$and][0][rpbId][$eq]=";
		return Promise.pure(seeOther(strapiUrl + rpbId));
	}

	/**
	 * @param ids The ids of the resources to unstar, or empty string to clear all
	 * @return If ids is empty: an OK result to confirm deletion of all starred
	 *         resources; if ids are given: A 303 SEE_OTHER result to the referrer
	 */
	public static Result clearStars(String ids) {
		if (ids.isEmpty()) {
			uncache(starredIds());
			uncacheLastSearchUrl();
			session(STARRED, "");
			return ok(stars.render(starredIds(), Collections.emptyList(), ""));
		}
		Arrays.asList(ids.split(",")).forEach(id -> unstar(id));
		return seeOther(request().getHeader(REFERER));
	}

	/**
	 * @param path The path to redirect to
	 * @return A 301 MOVED_PERMANENTLY redirect to the path
	 */
	public static Result redirect(String path) {
		return movedPermanently("/" + path);
	}

	/**
	 * @return The space-delimited IDs of the currently starred resouces
	 */
	public static String currentlyStarred() {
		String starred = session(STARRED);
		return starred == null ? "" : starred.trim();
	}

	private static List<String> starredIds() {
		return new ArrayList<>(Arrays.asList(currentlyStarred().split(" ")).stream()
				.filter(s -> !s.trim().isEmpty()).collect(Collectors.toList()));
	}

	public static Promise<Result> put(String id, String secret) throws FileNotFoundException, RecognitionException, IOException {
		boolean authorized = !secret.trim().isEmpty() && secret.equals(CONFIG.getString("secret"));
		if (authorized) {
			return transformAndIndex(id, request().body().asJson());
		} else {
			return Promise.pure(unauthorized(secret));
		}
	}

	public static Promise<Result> delete(String id, String secret) throws FileNotFoundException, RecognitionException, IOException {
		boolean authorized = !secret.trim().isEmpty() && secret.equals(CONFIG.getString("secret"));
		if (authorized) {
			return deleteFromIndex(id);
		} else {
			return Promise.pure(unauthorized(secret));
		}
	}

	public static Promise<Result> putIdFromData(String secret) throws FileNotFoundException, RecognitionException, IOException {
		return put(request().body().asJson().get("rpbId").textValue(), secret);
	}

	public static Promise<Result> deleteIdFromData(String secret) throws FileNotFoundException, RecognitionException, IOException {
		return delete(request().body().asJson().get("rpbId").textValue(), secret);
	}

	private static Promise<Result> deleteFromIndex(String id) throws UnsupportedEncodingException {
		Cache.remove(String.format("/%s", id));
		WSRequest request = WS.url(elasticsearchUrl(id)).setHeader("Content-Type", "application/json");
		return request.delete().map(response -> status(response.getStatus(), response.getBody()));
	}

	private static Promise<Result> transformAndIndex(String id, JsonNode jsonBody)
			throws IOException, FileNotFoundException, RecognitionException, UnsupportedEncodingException {
		JsonNode transformedJson = transform(jsonBody);
		Promise<JsonNode> dataPromise = id.startsWith("f") && transformedJson.has("hbzId") ? // hbz-Fremddaten
				addToLobidData(transformedJson) : Promise.pure(transformedJson);
		return dataPromise.flatMap(result -> {
			Cache.remove(String.format("/%s", id));
			WSRequest request = WS.url(elasticsearchUrl(id)).setHeader("Content-Type", "application/json");
			return request.put(result).map(response -> status(response.getStatus(), response.getBody()));
		});
	}

	private static JsonNode transform(JsonNode jsonBody)
			throws IOException, FileNotFoundException, RecognitionException {
		File input = new File("conf/output/test-output-strapi.json");
		File output = new File("conf/output/test-output-0.json");
		Files.write(Paths.get(input.getAbsolutePath()), jsonBody.toString().getBytes(Charset.forName(UTF_8)));
		ETL.main(new String[] {"conf/rpb-test-titel-to-lobid.flux"});
		String result = Files.readAllLines(Paths.get(output.getAbsolutePath())).stream().collect(Collectors.joining("\n"));
		return Json.parse(result);
	}

	private static Promise<JsonNode> addToLobidData(JsonNode transformedJson) {
		String lobidUrl = transformedJson.get("hbzId").textValue();
		WSRequest lobidRequest = WS.url(lobidUrl).setQueryParameter("format", "json");
		Promise<JsonNode> lobidPromise = lobidRequest.get().map(WSResponse::asJson);
		Promise<JsonNode> merged = lobidPromise.map(lobidJson -> mergeRecords(transformedJson, lobidJson));
		return merged;
	}

	private static JsonNode mergeRecords(JsonNode transformedJson, JsonNode lobidJson)
			throws JsonMappingException, JsonProcessingException {
		ObjectMapper objectMapper = new ObjectMapper();
		MapType mapType = TypeFactory.defaultInstance().constructMapType(Map.class, String.class, Object.class);
		Map<String, Object> transformedMap = objectMapper.readValue(transformedJson.toString(), mapType);
		Map<String, Object> lobidMap = objectMapper.readValue(lobidJson.toString(), mapType);
		lobidMap.remove("describedBy");
		transformedMap.put("hbzId", lobidMap.get("hbzId"));
		transformedMap.remove("type");
		transformedMap.keySet().forEach(key -> {
			Object transformedObject = transformedMap.get(key);
			Object lobidObject = lobidMap.getOrDefault(key, new ArrayList<Object>());
			Object values = transformedObject instanceof List ? mergeValues(transformedObject, lobidObject)
					: transformedObject;
			lobidMap.put(key, values);
		});
		return Json.toJson(lobidMap);
	}

	private static Object mergeValues(Object transformedObject, Object lobidObject) {
		List<Object> mergedValues = lobidObject instanceof List ? new ArrayList<>((List<?>) lobidObject)
				: Arrays.asList(lobidObject);
		mergedValues.addAll((List<?>) transformedObject);
		return mergedValues;
	}

	private static String elasticsearchUrl(String id) throws UnsupportedEncodingException {
		return "http://weywot3:9200/resources-rpb-test/resource/"
				+ URLEncoder.encode("https://lobid.org/resources/" + id, UTF_8);
	}
}

name := "rpb"

version := "0.1.1-SNAPSHOT"

scalaVersion := "2.11.12"

resolvers += Resolver.mavenLocal

libraryDependencies ++= Seq(
  cache,
  javaWs,
  "com.typesafe.play" % "play-test_2.11" % "2.4.11",
  "org.metafacture" % "metafacture-elasticsearch" % "7.0.0",
  "org.metafacture" % "metafacture-io" % "7.0.0",
  "org.metafacture" % "metafacture-xml" % "7.0.0",
  "org.metafacture" % "metafacture-biblio" % "7.0.0",
  "org.metafacture" % "metafacture-strings" % "7.0.0",
  "org.metafacture" % "metafacture-json" % "7.0.0",
  "org.metafacture" % "metafacture-flux" % "7.0.0",
  "org.metafacture" % "metafacture-triples" % "7.0.0",
  "org.metafacture" % "metafacture-formatting" % "7.0.0",
  "org.metafacture" % "metafacture-monitoring" % "7.0.0",
  "org.metafacture" % "metafacture-csv" % "7.0.0",
  "org.metafacture" % "metafacture-linkeddata" % "7.0.0",
  "org.metafacture" % "metafix" % "7.0.0",
  "org.elasticsearch" % "elasticsearch" % "5.6.16" withSources(),
  "org.elasticsearch.plugin" % "transport-netty4-client" % "5.6.16" withSources(),
  "com.sun.xml.bind" % "jaxb-impl" % "2.3.3" withSources(),
  "com.github.jsonld-java" % "jsonld-java" % "0.5.0",
  "org.apache.commons" % "commons-rdf-jena" % "0.5.0",
  "org.apache.commons" % "commons-csv" % "1.6",
  "org.apache.jena" % "jena-arq" % "3.0.1",
  "org.apache.jena" % "jena-core" % "3.0.1",
  "org.easytesting" % "fest-assert" % "1.4" % "test",
  "org.mockito" % "mockito-core" % "2.27.0" % "test",
  "org.mockito" % "mockito-junit-jupiter" % "2.27.0" % "test"
)

excludeDependencies ++= Seq(
  SbtExclusionRule("org.slf4j", "slf4j-simple")
)

dependencyOverrides ++= Set(
  "org.antlr" % "antlr-runtime" % "3.2",
  "org.eclipse.emf" % "org.eclipse.emf.common" % "2.24.0"
)

lazy val root = (project in file(".")).enablePlugins(PlayJava)

javacOptions ++= Seq("-source", "11", "-target", "11")

import com.typesafe.sbteclipse.core.EclipsePlugin.EclipseKeys

EclipseKeys.projectFlavor := EclipseProjectFlavor.Java // Java project. Don't expect Scala IDE
EclipseKeys.createSrc := EclipseCreateSrc.ValueSet(EclipseCreateSrc.ManagedClasses, EclipseCreateSrc.ManagedResources) // Use .class files instead of generated .scala files for views and routes
EclipseKeys.preTasks := Seq(compile in Compile) // Compile the project before generating Eclipse files, so that .class files for views and routes are present

trapExit := false

name := "rpb"

version := "0.1.0-SNAPSHOT"

scalaVersion := "2.11.11"

resolvers += Resolver.mavenLocal

libraryDependencies ++= Seq(
  cache,
  javaWs,
  "com.typesafe.play" % "play-test_2.11" % "2.4.11",
  "org.metafacture" % "metafacture-elasticsearch" % "5.7.0-rc1",
  "org.metafacture" % "metafacture-io" % "5.7.0-rc1",
  "org.metafacture" % "metafacture-strings" % "5.7.0-rc1",
  "org.metafacture" % "metafacture-json" % "5.7.0-rc1",
  "org.metafacture" % "metafacture-flux" % "5.7.0-rc1",
  "org.metafacture" % "metafacture-triples" % "5.7.0-rc1",
  "org.metafacture" % "metafacture-formatting" % "5.7.0-rc1",
  "org.metafacture" % "metafix" % "0.6.0-SNAPSHOT",
  "org.elasticsearch" % "elasticsearch" % "1.7.5" withSources(),
  "com.github.jsonld-java" % "jsonld-java" % "0.5.0",
  "org.apache.commons" % "commons-rdf-jena" % "0.5.0",
  "org.apache.commons" % "commons-csv" % "1.6",
  "org.apache.jena" % "jena-arq" % "3.0.1",
  "org.apache.jena" % "jena-core" % "3.0.1",
  "org.easytesting" % "fest-assert" % "1.4" % "test",
  "org.mockito" % "mockito-core" % "2.27.0" % "test",
  "org.mockito" % "mockito-junit-jupiter" % "2.27.0" % "test"
)

dependencyOverrides ++= Set(
  "org.antlr" % "antlr-runtime" % "3.2",
  "org.eclipse.emf" % "org.eclipse.emf.common" % "2.24.0"
)

lazy val root = (project in file(".")).enablePlugins(PlayJava)

javacOptions ++= Seq("-source", "1.8", "-target", "1.8")

import com.typesafe.sbteclipse.core.EclipsePlugin.EclipseKeys

EclipseKeys.projectFlavor := EclipseProjectFlavor.Java // Java project. Don't expect Scala IDE
EclipseKeys.createSrc := EclipseCreateSrc.ValueSet(EclipseCreateSrc.ManagedClasses, EclipseCreateSrc.ManagedResources) // Use .class files instead of generated .scala files for views and routes
EclipseKeys.preTasks := Seq(compile in Compile) // Compile the project before generating Eclipse files, so that .class files for views and routes are present

trapExit := false

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Security.Cryptography;
using System.Text.Json.Nodes;
using System.Threading;
using System.Threading.Tasks;

namespace Kagayoi.Npm
{
    public static class ArchiveIntegrationTests
    {
        private sealed class DenyHttp : HttpMessageHandler
        {
            internal int Calls;
            protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
            {
                Calls++;
                throw new InvalidOperationException("Network is forbidden in archive integration tests.");
            }
        }
        private static void Check(bool condition, string message) => Publisher.Require(condition, message);

        public static void Run(string packageFile, string integrity, string name, string version, string workDirectory)
        {
            var original = File.ReadAllBytes(packageFile);
            Check(integrity == "sha512-" + Convert.ToBase64String(SHA512.HashData(original)), "Verifier integrity differs.");
            var branch = "refs/heads/release/" + version;
            // Source context only: no process environment, OIDC tokens or publication capability.
            var fixture = new Dictionary<string, string>(StringComparer.Ordinal) {
                ["GITHUB_SERVER_URL"] = "https://github.com", ["GITHUB_REPOSITORY"] = "fixture/archive",
                ["GITHUB_WORKFLOW_REF"] = "fixture/archive/.github/workflows/offline.yml@" + branch,
                ["GITHUB_REF"] = branch, ["GITHUB_REF_NAME"] = "release/" + version,
                ["GITHUB_SHA"] = new string('a', 40), ["GITHUB_EVENT_NAME"] = "push",
                ["GITHUB_REPOSITORY_ID"] = "1", ["GITHUB_REPOSITORY_OWNER_ID"] = "2",
                ["RUNNER_ENVIRONMENT"] = "github-hosted", ["GITHUB_RUN_ID"] = "3", ["GITHUB_RUN_ATTEMPT"] = "1"
            };
            using (var handler = new DenyHttp())
            using (var client = new HttpClient(handler))
            {
                try
                {
                    var result = JsonNode.Parse(Publisher.Run(packageFile, integrity, null, true, fixture, client, false));
                    var metadata = result["Metadata"];
                    Check(Publisher.Text(metadata["name"]) == name, "Metadata package name differs.");
                    Check(Publisher.Text(metadata["dist-tags"]["latest"]) == version, "Metadata latest version differs.");
                    var manifest = metadata["versions"][version];
                    Check(Publisher.Text(manifest["version"]) == version && Publisher.Text(manifest["name"]) == name, "Archive package identity differs.");
                    Check(Publisher.Text(manifest["dist"]["integrity"]) == integrity, "Metadata integrity differs.");
                    var attachment = metadata["_attachments"][name + "-" + version + ".tgz"];
                    Check(attachment["length"].GetValue<int>() == original.Length && Convert.FromBase64String(Publisher.Text(attachment["data"])).SequenceEqual(original), "Attachment bytes or length differ.");
                    Check(handler.Calls == 0, "Success path attempted external work.");
                    Console.WriteLine("PASS verified archive metadata, attachment bytes; HTTP=0");

                    var tampered = (byte[])original.Clone();
                    tampered[tampered.Length - 1] ^= 1;
                    var copy = Path.Combine(workDirectory, "tampered-copy.tgz");
                    File.WriteAllBytes(copy, tampered);
                    bool rejected = false;
                    try { Publisher.Run(copy, integrity, null, true, fixture, client, false); }
                    catch (InvalidOperationException error) when (error.Message == "Verified archive integrity mismatch.") { rejected = true; }
                    Check(rejected, "Tampered archive was not rejected by the exact integrity guard.");
                    Check(handler.Calls == 0, "Failure path attempted external work.");
                    Console.WriteLine("PASS tampered copy rejected by integrity guard; HTTP=0");
                }
                finally { Check(File.ReadAllBytes(packageFile).SequenceEqual(original), "Original archive changed."); }
            }
            Console.WriteLine("PASS original archive unchanged; no publication request attempted");
        }
    }
}

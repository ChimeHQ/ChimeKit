#if !canImport(ProcessEnv)
/// This is a stand-in to make building easier for platforms that ProcessEnv does not support.
public struct Process {
	public struct ExecutionParameters: Codable {}
}
#endif

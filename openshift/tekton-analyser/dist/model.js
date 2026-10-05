export function resourceName(metadata) {
    return metadata.name ?? (metadata.generateName ? `${metadata.generateName}*` : '<unnamed>');
}
//# sourceMappingURL=model.js.map
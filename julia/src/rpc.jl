# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
# Unix-domain RPC only. No TCP listener is provided.
# Abjad framing matches abjad-wstp: 16-byte header, 8-byte big-endian total.
# Neuro framing matches elliptic-neuroregex: uint16 op length, uint32 JSON length.

const ABJAD_MAGIC = 0x41424a44
const ABJAD_MAX = 65536
const NEURO_MAX = 1024 * 1024

function _be16(x::Integer)
    v = UInt16(x)
    UInt8[(v >> 8) % UInt8, v % UInt8]
end
function _be32(x::Integer)
    v = UInt32(x)
    UInt8[(v >> 24) % UInt8, (v >> 16) % UInt8, (v >> 8) % UInt8, v % UInt8]
end
function _ld16(b)
    UInt16(b[1]) << 8 | UInt16(b[2])
end
function _ld32(b)
    UInt32(b[1]) << 24 | UInt32(b[2]) << 16 | UInt32(b[3]) << 8 | UInt32(b[4])
end

function _read_exact(io, n::Integer; timeout_s::Float64=5.0)
    n == 0 && return UInt8[]
    buf = Vector{UInt8}(undef, n)
    timer = Timer(timeout_s) do _
        try close(io) catch end
    end
    try
        read!(io, buf)
        return buf
    catch
        return nothing
    finally
        close(timer)
    end
end

function _prepare_socket(path)
    length(path) >= 108 && error("socket path too long")
    isempty(path) && error("empty socket path")
    ccall(:umask, UInt32, (UInt32,), 0o077)
    rm(path, force=true)
    server = listen(path)
    chmod(path, 0o600)
    server
end

function _abjad_status(bytes)
    try
        return (UInt16(0), abjad_sum(bytes))
    catch e
        e isa AbjadError || rethrow()
        return (UInt16(1), UInt64(0))
    end
end

function serve_abjad_client(io; timeout_s=5.0, max_requests=1024)
    for _ in 1:max_requests
        hdr = _read_exact(io, 16; timeout_s)
        hdr === nothing && return
        magic = _ld32(hdr[1:4])
        ver = _ld16(hdr[5:6])
        op = _ld16(hdr[7:8])
        id = _ld32(hdr[9:12])
        len = _ld32(hdr[13:16])
        (magic == ABJAD_MAGIC && ver == 1 && len <= ABJAD_MAX) || return
        payload = _read_exact(io, len; timeout_s)
        payload === nothing && return
        status, value = if op == 1
            _abjad_status(payload)
        else
            (UInt16(1), UInt64(0))
        end
        out = UInt8[]
        append!(out, _be32(ABJAD_MAGIC))
        append!(out, _be16(1))
        append!(out, _be16(status))
        append!(out, _be32(id))
        append!(out, _be32(8))
        for shift in (56, 48, 40, 32, 24, 16, 8, 0)
            push!(out, UInt8((value >> shift) % UInt8))
        end
        write(io, out)
    end
end

function serve_abjad(path::AbstractString; timeout_s=5.0, max_requests=1024)
    server = _prepare_socket(path)
    try
        while true
            client = try
                accept(server)
            catch e
                e isa InterruptException && rethrow()
                break
            end
            try
                serve_abjad_client(client; timeout_s, max_requests)
            catch e
                e isa InterruptException && rethrow()
            finally
                close(client)
            end
        end
    finally
        close(server)
        rm(path, force=true)
    end
end

function abjad_call(path::AbstractString, text::AbstractString; id::Integer=1, timeout_s=5.0)
    payload = Vector{UInt8}(codeunits(String(text)))
    length(payload) > ABJAD_MAX && throw(DomainError2("payload too large"))
    sock = connect(path)
    try
        hdr = UInt8[]
        append!(hdr, _be32(ABJAD_MAGIC))
        append!(hdr, _be16(1))
        append!(hdr, _be16(1))
        append!(hdr, _be32(id))
        append!(hdr, _be32(length(payload)))
        write(sock, hdr)
        write(sock, payload)
        reply = _read_exact(sock, 24; timeout_s)
        reply === nothing && throw(DomainError2("short reply"))
        _ld32(reply[1:4]) == ABJAD_MAGIC || throw(DomainError2("bad magic"))
        status = _ld16(reply[7:8])
        echo = _ld32(reply[9:12])
        value = UInt64(0)
        for b in reply[17:24]
            value = (value << 8) | UInt64(b)
        end
        return (status=Int(status), id=Int(echo), value=value)
    finally
        close(sock)
    end
end

function serve_neuro_client(io, state::Corpus; timeout_s=5.0, max_requests=256)
    for _ in 1:max_requests
        hdr = _read_exact(io, 6; timeout_s)
        hdr === nothing && return
        op_len = Int(_ld16(hdr[1:2]))
        js_len = Int(_ld32(hdr[3:6]))
        (1 <= op_len <= 64 && 0 <= js_len <= NEURO_MAX) || return
        opb = _read_exact(io, op_len; timeout_s)
        jsb = _read_exact(io, js_len; timeout_s)
        (opb === nothing || jsb === nothing) && return
        (0 in opb || 0 in jsb) && return
        op = String(opb)
        js = String(jsb)
        body = try
            neuro_dispatch(op, js, state)
        catch
            json_text(Dict("error" => "operation rejected"))
        end
        nbytes = codeunits(body)
        if sizeof(nbytes) > NEURO_MAX
            body = json_text(Dict("error" => "response too large"))
            nbytes = codeunits(body)
        end
        write(io, _be32(sizeof(nbytes)))
        write(io, nbytes)
    end
end

function serve_neuro(path::AbstractString; timeout_s=5.0, max_requests=256)
    server = _prepare_socket(path)
    state = Corpus()
    try
        while true
            client = try
                accept(server)
            catch e
                e isa InterruptException && rethrow()
                break
            end
            try
                serve_neuro_client(client, state; timeout_s, max_requests)
            catch e
                e isa InterruptException && rethrow()
            finally
                close(client)
            end
        end
    finally
        close(server)
        rm(path, force=true)
    end
end

function neuro_call(path::AbstractString, op::AbstractString, js::AbstractString; timeout_s=5.0)
    length(op) > 64 && throw(DomainError2("operation name too long"))
    sizeof(js) > NEURO_MAX && throw(DomainError2("payload too large"))
    sock = connect(path)
    try
        hdr = UInt8[]
        append!(hdr, _be16(sizeof(op)))
        append!(hdr, _be32(sizeof(js)))
        write(sock, hdr)
        write(sock, op)
        write(sock, js)
        lenb = _read_exact(sock, 4; timeout_s)
        lenb === nothing && throw(DomainError2("short reply"))
        n = Int(_ld32(lenb))
        0 <= n <= NEURO_MAX || throw(DomainError2("response too large"))
        body = _read_exact(sock, n; timeout_s)
        body === nothing && throw(DomainError2("short body"))
        return String(body)
    finally
        close(sock)
    end
end

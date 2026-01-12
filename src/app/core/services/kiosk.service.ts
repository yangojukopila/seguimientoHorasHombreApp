import { Injectable } from '@angular/core';
import { SupabaseService } from './supabase.service';
import { CheckInRequest, CheckOutRequest, TimeRecord, Island } from '../models';

@Injectable({
    providedIn: 'root'
})
export class KioskService {
    private readonly ISLAND_TOKEN_KEY = 'island_token';

    constructor(private supabase: SupabaseService) { }

    // Token management
    setIslandToken(token: string): void {
        localStorage.setItem(this.ISLAND_TOKEN_KEY, token);
    }

    getIslandToken(): string | null {
        return localStorage.getItem(this.ISLAND_TOKEN_KEY);
    }

    clearIslandToken(): void {
        localStorage.removeItem(this.ISLAND_TOKEN_KEY);
    }

    // Validate island token
    async validateToken(token: string): Promise<{ valid: boolean; island?: Island; error?: string }> {
        try {
            const { data, error } = await this.supabase
                .from('islands')
                .select('*')
                .eq('token', token)
                .eq('status', 'active')
                .single();

            if (error || !data) {
                return { valid: false, error: 'Token inválido o isla inactiva' };
            }

            // Update last activity
            await this.supabase
                .from('islands')
                .update({ last_activity: new Date().toISOString() })
                .eq('id', data.id);

            return { valid: true, island: data };
        } catch (err) {
            return { valid: false, error: 'Error validando token' };
        }
    }

    // Check if employee has active shift
    async hasActiveShift(employeeId: string): Promise<boolean> {
        const { data, error } = await this.supabase.client
            .from('time_records')
            .select('id')
            .eq('employee_id', employeeId)
            .is('check_out', null)
            .limit(1);

        return !error && data && data.length > 0;
    }

    async getActiveTimeRecord(employeeId: string): Promise<{ data: TimeRecord | null; error: string | null }> {
        try {
            const { data, error } = await this.supabase.client
                .from('time_records')
                .select('*, project:projects(*)')
                .eq('employee_id', employeeId)
                .is('check_out', null)
                .single();

            if (error) {
                return { data: null, error: error.message };
            }

            return { data: data as TimeRecord, error: null };
        } catch (err) {
            console.error('Error getting active time record:', err);
            return { data: null, error: 'Error en el sistema al buscar turno activo' };
        }
    }

    // Get employee by cedula
    async getEmployeeByCedula(cedula: string): Promise<{ employee?: any; error?: string }> {
        try {
            const { data, error } = await this.supabase
                .from('employees')
                .select('*')
                .eq('cedula', cedula)
                .eq('status', 'active')
                .single();

            if (error || !data) {
                return { error: 'Empleado no encontrado o inactivo' };
            }

            return { employee: data };
        } catch (err) {
            return { error: 'Error buscando empleado' };
        }
    }

    // Check-in
    async checkIn(request: CheckInRequest): Promise<{ success: boolean; error?: string }> {
        try {
            // Validate token
            const tokenValidation = await this.validateToken(request.island_token);
            if (!tokenValidation.valid) {
                return { success: false, error: tokenValidation.error };
            }

            // Get employee
            const { employee, error: empError } = await this.getEmployeeByCedula(request.cedula);
            if (empError) {
                return { success: false, error: empError };
            }

            // Check for active shift
            const hasActive = await this.hasActiveShift(employee.id);
            if (hasActive) {
                return { success: false, error: 'Ya tiene un turno activo' };
            }

            // Verify project is active
            const { data: project, error: projError } = await this.supabase
                .from('projects')
                .select('*')
                .eq('id', request.project_id)
                .eq('status', 'active')
                .single();

            if (projError || !project) {
                return { success: false, error: 'Proyecto no encontrado o cerrado' };
            }

            // Create time record
            const { error: insertError } = await this.supabase
                .from('time_records')
                .insert({
                    employee_id: employee.id,
                    project_id: request.project_id,
                    island_id: tokenValidation.island!.id,
                    check_in: new Date().toISOString()
                });

            if (insertError) {
                return { success: false, error: 'Error registrando entrada' };
            }

            return { success: true };
        } catch (err) {
            console.error('Check-in error:', err);
            return { success: false, error: 'Error en el sistema' };
        }
    }

    // Check-out
    async checkOut(request: CheckOutRequest): Promise<{ success: boolean; error?: string }> {
        try {
            // Validate token
            const tokenValidation = await this.validateToken(request.island_token);
            if (!tokenValidation.valid) {
                return { success: false, error: tokenValidation.error };
            }

            // Get employee
            const { employee, error: empError } = await this.getEmployeeByCedula(request.cedula);
            if (empError) {
                return { success: false, error: empError };
            }

            // Get active shift
            const { data: activeRecord, error: recordError } = await this.supabase
                .from('time_records')
                .select('*')
                .eq('employee_id', employee.id)
                .is('check_out', null)
                .single();

            if (recordError || !activeRecord) {
                return { success: false, error: 'No tiene turno activo' };
            }

            // Update with check-out time
            const { error: updateError } = await this.supabase
                .from('time_records')
                .update({ check_out: new Date().toISOString() })
                .eq('id', activeRecord.id);

            if (updateError) {
                return { success: false, error: 'Error registrando salida' };
            }

            return { success: true };
        } catch (err) {
            console.error('Check-out error:', err);
            return { success: false, error: 'Error en el sistema' };
        }
    }

    // Get active projects
    async getActiveProjects() {
        return await this.supabase
            .from('projects')
            .select('*')
            .eq('status', 'active')
            .order('name');
    }
}
